import { openLab } from "@/api/content";
import { useEffect, useState } from "react";
import { useParams } from "react-router-dom";
import "./LabWorkspace.css";

// code-server URL — configurable via Vite env variable.
// - Dev: Vite proxy at /code-server/ → http://localhost:8081
// - Prod: set VITE_CODE_SERVER_URL to the code-server address
const CODE_SERVER_URL = import.meta.env.VITE_CODE_SERVER_URL || "/code-server/";

interface LabWorkspaceProps {
  labId: string;
  moduleId: string;
}

/** Build the code-server URL that opens a specific lab folder.
 *  code-server mounts the whole lab-root as /home/coder/project. Opening the
 *  lab's own subfolder means learners only see files for the current lab. */
function workspaceUrl(labId: string): string {
  const folder = `/home/coder/project/${labId}`;
  const separator = CODE_SERVER_URL.includes("?") ? "&" : "?";
  return `${CODE_SERVER_URL}${separator}folder=${encodeURIComponent(folder)}`;
}

export function LabWorkspace({ labId, moduleId }: LabWorkspaceProps) {
  const { courseId = "" } = useParams();
  const [seeding, setSeeding] = useState(true);
  const [error, setError] = useState<string | null>(null);

  // Seed the lab directory on mount — this copies starter files (.tf, etc.)
  // into the lab workspace so code-server has content to show.
  useEffect(() => {
    let cancelled = false;
    (async () => {
      try {
        await openLab(courseId, moduleId, labId);
      } catch (err) {
        if (!cancelled) {
          console.error("failed to seed lab:", err);
          setError("Failed to seed lab files. The workspace may be empty.");
        }
      } finally {
        if (!cancelled) setSeeding(false);
      }
    })();
    return () => {
      cancelled = true;
    };
  }, [courseId, moduleId, labId]);

  if (seeding) {
    return (
      <div className="lab-workspace">
        <div className="lab-workspace__loading">Seeding lab files…</div>
      </div>
    );
  }

  if (error) {
    return (
      <div className="lab-workspace">
        <div className="lab-workspace__error">{error}</div>
      </div>
    );
  }

  return (
    <div className="lab-workspace">
      <iframe
        src={workspaceUrl(labId)}
        title="VS Code Editor"
        className="lab-workspace__iframe"
        allow="clipboard-read; clipboard-write; fullscreen"
      />
    </div>
  );
}
