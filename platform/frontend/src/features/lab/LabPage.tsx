import {
  type GradeResult,
  type LabTask as LabTaskType,
  type TaskResult,
  applyTaskWorkspace,
  checkLab,
  checkTask,
  openLab,
  useCourse,
  useLabInstructions,
  useProgress,
} from "@/api/content";
import { Icon } from "@/components/Icon";
import { Button } from "@canonical/react-components";
import { useQueryClient } from "@tanstack/react-query";
import { useEffect, useMemo, useState } from "react";
import { useParams } from "react-router-dom";
import { LabInstructionsPanel } from "./LabInstructionsPanel";
import { LabTask } from "./LabTask";
import { LabWorkspace } from "./LabWorkspace";
import { TerminalPane } from "./TerminalPane";
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
  const { data: course } = useCourse(courseId);
  const [viewMode, setViewMode] = useState<ViewMode>("split");
  const [currentTaskIndex, setCurrentTaskIndex] = useState(0);
  const [taskResults, setTaskResults] = useState<Record<string, TaskResult>>(
    {},
  );
  const [checkingTaskId, setCheckingTaskId] = useState<string | null>(null);
  const [grade, setGrade] = useState<GradeResult | null>(null);
  const [checkingLab, setCheckingLab] = useState(false);

  // Lab seeding: create the lab working directory and copy starter files.
  // Shared by both code-server and terminal workspace modes.
  const [labPath, setLabPath] = useState<string | null>(null);
  const [seeding, setSeeding] = useState(true);
  const [seedError, setSeedError] = useState<string | null>(null);

  useEffect(() => {
    let cancelled = false;
    (async () => {
      setSeeding(true);
      setSeedError(null);
      try {
        const result = await openLab(courseId, moduleId, labId);
        if (!cancelled) setLabPath(result.labPath);
      } catch (err) {
        if (!cancelled) {
          console.error("failed to seed lab:", err);
          setSeedError("Failed to seed lab files. The workspace may be empty.");
        }
      } finally {
        if (!cancelled) setSeeding(false);
      }
    })();
    return () => {
      cancelled = true;
    };
  }, [courseId, moduleId, labId]);

  // Determine workspace type from course metadata. Default to code-server.
  const workspaceType = course?.workspace ?? "code-server";

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

  // Restore position to the first incomplete task on load and apply the
  // corresponding workspace so code-server reflects the current task.
  useEffect(() => {
    if (tasks.length === 0) return;
    const firstIncomplete = tasks.findIndex((t) => !completedTaskIds.has(t.id));
    const index = firstIncomplete === -1 ? tasks.length - 1 : firstIncomplete;
    setCurrentTaskIndex(index);
    void applyTaskWorkspace(courseId, moduleId, labId, tasks[index].id);
  }, [tasks, completedTaskIds, courseId, moduleId, labId]);

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
    // Dev mode: unrestricted navigation so authors/testers can jump between
    // tasks without completing them. In production this would be gated so
    // learners can only view completed tasks or the next unlocked one.
    setCurrentTaskIndex(index);
    void applyTaskWorkspace(courseId, moduleId, labId, tasks[index].id);
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
              <Icon name={grade.passed ? "success" : "error"} size={14} />
              {grade.passed ? " Lab passed" : " Lab check failed"}
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
              <Icon name="book" size={16} />
            </button>
            <button
              type="button"
              className={viewMode === "split" ? "active" : ""}
              onClick={() => setViewMode("split")}
              title="Split view"
            >
              <Icon name="expand" size={16} />
            </button>
            <button
              type="button"
              className={viewMode === "workspace" ? "active" : ""}
              onClick={() => setViewMode("workspace")}
              title="Workspace only"
            >
              <Icon name="open-terminal" size={16} />
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
            <Icon name="success" size={14} />
            Check lab
          </Button>
        </div>
      </div>

      {grade && !grade.passed && (
        <div className="lab-page__grade-panel">
          <strong>Lab check results:</strong>
          <ul>
            {grade.tasks.map((t) => (
              <li key={t.id} className={t.passed ? "task--pass" : "task--fail"}>
                <Icon
                  name={t.passed ? "success" : "error"}
                  className="task__icon"
                  size={16}
                  light
                />
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
                    return (
                      <button
                        key={task.id}
                        type="button"
                        className={`lab-page__step ${active ? "lab-page__step--active" : ""} ${completed ? "lab-page__step--done" : ""}`}
                        onClick={() => handleStepClick(idx)}
                        title={task.title}
                      >
                        <span className="lab-page__step-marker">
                          {completed ? (
                            <Icon name="success" size={12} />
                          ) : (
                            idx + 1
                          )}
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
            {seeding ? (
              <div className="lab-workspace">
                <div className="lab-workspace__loading">
                  Seeding lab files…
                </div>
              </div>
            ) : seedError ? (
              <div className="lab-workspace">
                <div className="lab-workspace__error">{seedError}</div>
              </div>
            ) : workspaceType === "terminal" ? (
              <TerminalPane labPath={labPath ?? undefined} />
            ) : (
              <LabWorkspace labPath={labPath ?? labId} />
            )}
          </div>
        )}
      </div>
    </div>
  );
}
