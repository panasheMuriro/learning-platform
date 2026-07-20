import { checkLab, useLabInstructions } from "@/api/content";
import type { GradeResult } from "@/api/content";
import { Button } from "@canonical/react-components";
import { useState } from "react";
import { useParams } from "react-router-dom";
import { LabInstructionsPanel } from "./LabInstructionsPanel";
import { LabWorkspace } from "./LabWorkspace";
import "./LabPage.css";

type ViewMode = "split" | "instructions" | "workspace";

export function LabPage() {
  const { moduleId = "", labId = "" } = useParams();
  const { data: lab, isLoading, error } = useLabInstructions(moduleId, labId);
  const [viewMode, setViewMode] = useState<ViewMode>("split");
  const [grade, setGrade] = useState<GradeResult | null>(null);
  const [checking, setChecking] = useState(false);

  const handleCheck = async () => {
    setChecking(true);
    try {
      const result = await checkLab(moduleId, labId);
      setGrade(result);
      if (result.passed) setViewMode("workspace");
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
          <h1 className="p-heading--4">{lab.title}</h1>
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
            <Button
              appearance={viewMode === "instructions" ? "positive" : "base"}
              onClick={() => setViewMode("instructions")}
              title="Instructions only"
            >
              📖
            </Button>
            <Button
              appearance={viewMode === "split" ? "positive" : "base"}
              onClick={() => setViewMode("split")}
              title="Split view"
            >
              ⬌
            </Button>
            <Button
              appearance={viewMode === "workspace" ? "positive" : "base"}
              onClick={() => setViewMode("workspace")}
              title="Workspace only"
            >
              ⌨
            </Button>
          </div>
          <Button
            appearance="positive"
            onClick={handleCheck}
            disabled={checking}
            loading={checking}
          >
            {checking ? "Checking…" : "✓ Check"}
          </Button>
        </div>
      </div>

      {grade && !grade.passed && (
        <div className="lab-page__grade-panel">
          <strong>Check results:</strong>
          <ul className="lab-page__task-list">
            {grade.tasks.map((t) => (
              <li key={t.id} className={t.passed ? "task--pass" : "task--fail"}>
                <span>{t.passed ? "✅" : "❌"}</span>
                <strong>{t.name}</strong>
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
