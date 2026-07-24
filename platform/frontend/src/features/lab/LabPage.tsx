import { checkLab, useLabInstructions } from "@/api/content";
import type { GradeResult } from "@/api/content";
import { Button } from "@canonical/react-components";
import { useQueryClient } from "@tanstack/react-query";
import { useState } from "react";
import { useParams } from "react-router-dom";
import { LabInstructionsPanel } from "./LabInstructionsPanel";
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
  const [viewMode, setViewMode] = useState<ViewMode>("split");
  const [grade, setGrade] = useState<GradeResult | null>(null);
  const [checking, setChecking] = useState(false);

  const handleCheck = async () => {
    setChecking(true);
    try {
      const result = await checkLab(courseId, moduleId, labId);
      setGrade(result);
      if (result.passed) setViewMode("workspace");
      // Refresh progress so the sidebar checkmark updates.
      await queryClient.invalidateQueries({
        queryKey: ["progress", courseId],
      });
    } finally {
      setChecking(false);
    }
  };

  if (isLoading) return <div className="course-content">Loading lab…</div>;
  if (error || !lab)
    return <div className="course-content">Failed to load lab.</div>;

  return (
    <div className="lab-page">
      <div className="lab-page__toolbar">
        <div className="lab-page__toolbar-left">
          <h1>{lab.title}</h1>
          {grade && (
            <span
              className={`lab-page__badge ${grade.passed ? "lab-page__badge--pass" : "lab-page__badge--fail"}`}
            >
              {grade.passed ? "✅ Passed" : "❌ Failed"}
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
            onClick={handleCheck}
            disabled={checking}
          >
            ✓ Check
          </Button>
        </div>
      </div>
      {grade && !grade.passed && (
        <div className="lab-page__grade-panel">
          <strong>Check results:</strong>
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
            <LabInstructionsPanel markdown={lab.markdown} />
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
