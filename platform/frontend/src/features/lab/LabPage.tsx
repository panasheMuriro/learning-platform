import {
  type GradeResult,
  type LabTask as LabTaskType,
  type TaskResult,
  checkLab,
  checkTask,
  useLabInstructions,
  useProgress,
} from "@/api/content";
import { Button } from "@canonical/react-components";
import { useQueryClient } from "@tanstack/react-query";
import { useEffect, useMemo, useState } from "react";
import { useParams } from "react-router-dom";
import { LabInstructionsPanel } from "./LabInstructionsPanel";
import { LabTask } from "./LabTask";
import { LabWorkspace } from "./LabWorkspace";
import "./LabPage.css";

type ViewMode = "split" | "instructions" | "workspace";

export function LabPage() {
  const { courseId = "", moduleId = "", labId = "" } = useParams();
  const queryClient = useQueryClient();
  const {
    data: lab,
    isLoading,
    error,
  } = useLabInstructions(courseId, moduleId, labId);
  const { data: progress } = useProgress(courseId);
  const [viewMode, setViewMode] = useState<ViewMode>("split");
  const [currentTaskIndex, setCurrentTaskIndex] = useState(0);
  const [taskResults, setTaskResults] = useState<Record<string, TaskResult>>(
    {},
  );
  const [checkingTaskId, setCheckingTaskId] = useState<string | null>(null);
  const [grade, setGrade] = useState<GradeResult | null>(null);
  const [checkingLab, setCheckingLab] = useState(false);

  const tasks = useMemo<LabTaskType[]>(() => {
    if (lab?.tasks && lab.tasks.length > 0) return lab.tasks;
    return [];
  }, [lab]);

  // Completed task IDs come from persisted progress, merged with local results
  // from the current session.
  const completedTaskIds = useMemo(() => {
    const completed = new Set<string>();
    const moduleProgress = progress?.modules.find(
      (m) => m.moduleId === moduleId,
    );
    const persisted = moduleProgress?.tasksCompleted?.[labId] ?? [];
    for (const id of persisted) {
      completed.add(id);
    }
    for (const [id, result] of Object.entries(taskResults)) {
      if (result.passed) completed.add(id);
    }
    return completed;
  }, [progress, moduleId, labId, taskResults]);

  // Restore position to the first incomplete task on load.
  useEffect(() => {
    if (tasks.length === 0) return;
    const firstIncomplete = tasks.findIndex((t) => !completedTaskIds.has(t.id));
    setCurrentTaskIndex(
      firstIncomplete === -1 ? tasks.length - 1 : firstIncomplete,
    );
  }, [tasks, completedTaskIds]);

  const handleCheckTask = async (taskId: string) => {
    setCheckingTaskId(taskId);
    try {
      const result = await checkTask(courseId, moduleId, labId, taskId);
      const taskResult = result.tasks.find((t) => t.id === taskId);
      if (taskResult) {
        setTaskResults((prev) => ({ ...prev, [taskId]: taskResult }));
      }
      await queryClient.invalidateQueries({
        queryKey: ["progress", courseId],
      });
    } finally {
      setCheckingTaskId(null);
    }
  };

  const handleCheckLab = async () => {
    setCheckingLab(true);
    try {
      const result = await checkLab(courseId, moduleId, labId);
      setGrade(result);
      await queryClient.invalidateQueries({
        queryKey: ["progress", courseId],
      });
    } finally {
      setCheckingLab(false);
    }
  };

  const handleNext = () => {
    if (currentTaskIndex < tasks.length - 1) {
      setCurrentTaskIndex(currentTaskIndex + 1);
    }
  };

  const handleStepClick = (index: number) => {
    // Allow free navigation to previous or current task; only completed tasks
    // unlock future ones.
    if (
      index <= currentTaskIndex ||
      completedTaskIds.has(tasks[index - 1]?.id ?? "")
    ) {
      setCurrentTaskIndex(index);
    }
  };

  if (isLoading) return <div className="course-content">Loading lab…</div>;
  if (error || !lab)
    return <div className="course-content">Failed to load lab.</div>;

  const currentTask = tasks[currentTaskIndex];
  const allTasksCompleted =
    tasks.length > 0 && tasks.every((t) => completedTaskIds.has(t.id));

  return (
    <div className="lab-page">
      <div className="lab-page__toolbar">
        <div className="lab-page__toolbar-left">
          <h1>{lab.title}</h1>
          {grade && (
            <span
              className={`lab-page__badge ${grade.passed ? "lab-page__badge--pass" : "lab-page__badge--fail"}`}
            >
              {grade.passed ? "✅ Lab passed" : "❌ Lab check failed"}
            </span>
          )}
        </div>
        <div className="lab-page__toolbar-right">
          <div className="lab-page__view-toggle">
            <button
              type="button"
              className={viewMode === "instructions" ? "active" : ""}
              onClick={() => setViewMode("instructions")}
              title="Instructions only"
            >
              📖
            </button>
            <button
              type="button"
              className={viewMode === "split" ? "active" : ""}
              onClick={() => setViewMode("split")}
              title="Split view"
            >
              ⬌
            </button>
            <button
              type="button"
              className={viewMode === "workspace" ? "active" : ""}
              onClick={() => setViewMode("workspace")}
              title="Workspace only"
            >
              ⌨
            </button>
          </div>
          <Button
            type="button"
            appearance="positive"
            onClick={handleCheckLab}
            disabled={checkingLab || !allTasksCompleted}
            title={
              allTasksCompleted
                ? "Verify the whole lab"
                : "Complete all tasks before checking the lab"
            }
          >
            ✓ Check lab
          </Button>
        </div>
      </div>

      {grade && !grade.passed && (
        <div className="lab-page__grade-panel">
          <strong>Lab check results:</strong>
          <ul>
            {grade.tasks.map((t) => (
              <li key={t.id} className={t.passed ? "task--pass" : "task--fail"}>
                <span className="task__icon">{t.passed ? "✅" : "❌"}</span>
                <span className="task__name">{t.name}</span>
                <span className="task__msg">{t.message}</span>
              </li>
            ))}
          </ul>
        </div>
      )}

      <div className={`lab-page__body lab-page__body--${viewMode}`}>
        {(viewMode === "instructions" || viewMode === "split") && (
          <div className="lab-page__instructions">
            {tasks.length > 0 && currentTask ? (
              <>
                <div className="lab-page__stepper">
                  {tasks.map((task, idx) => {
                    const completed = completedTaskIds.has(task.id);
                    const active = idx === currentTaskIndex;
                    const clickable =
                      idx <= currentTaskIndex ||
                      completedTaskIds.has(tasks[idx - 1]?.id ?? "");
                    return (
                      <button
                        key={task.id}
                        type="button"
                        disabled={!clickable}
                        className={`lab-page__step ${active ? "lab-page__step--active" : ""} ${completed ? "lab-page__step--done" : ""} ${clickable ? "lab-page__step--clickable" : ""}`}
                        onClick={() => handleStepClick(idx)}
                        title={task.title}
                      >
                        <span className="lab-page__step-marker">
                          {completed ? "✓" : idx + 1}
                        </span>
                        <span className="lab-page__step-title">
                          {task.title}
                        </span>
                      </button>
                    );
                  })}
                </div>
                <LabTask
                  task={currentTask}
                  taskNumber={currentTaskIndex + 1}
                  totalTasks={tasks.length}
                  taskResult={taskResults[currentTask.id]}
                  completed={completedTaskIds.has(currentTask.id)}
                  onCheck={() => handleCheckTask(currentTask.id)}
                  onNext={handleNext}
                  checking={checkingTaskId === currentTask.id}
                />
              </>
            ) : (
              <LabInstructionsPanel markdown={lab.markdown} />
            )}
          </div>
        )}
        {(viewMode === "workspace" || viewMode === "split") && (
          <div className="lab-page__workspace">
            <LabWorkspace labId={labId} moduleId={moduleId} />
          </div>
        )}
      </div>
    </div>
  );
}
