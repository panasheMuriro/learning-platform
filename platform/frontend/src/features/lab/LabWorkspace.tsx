import "./LabWorkspace.css";

// code-server URL — configurable via Vite env variable.
// - Dev: Vite proxy at /code-server/ → http://localhost:8081
// - Prod: set VITE_CODE_SERVER_URL to the code-server address
const CODE_SERVER_URL = import.meta.env.VITE_CODE_SERVER_URL || "/code-server/";

interface LabWorkspaceProps {
  /** Lab directory path (relative to lab root), used to open the correct
   * subfolder in code-server. */
  labPath: string;
}

/** Build the code-server URL that opens a specific lab folder.
 *  code-server mounts the whole lab-root as /home/coder/project. Opening the
 *  lab's own subfolder means learners only see files for the current lab. */
function workspaceUrl(labPath: string): string {
  const folder = `/home/coder/project/${labPath}`;
  const separator = CODE_SERVER_URL.includes("?") ? "&" : "?";
  return `${CODE_SERVER_URL}${separator}folder=${encodeURIComponent(folder)}`;
}

/** Renders the code-server iframe for a lab. Seeding is handled by the parent
 * (LabPage) so both code-server and terminal modes share the same logic. */
export function LabWorkspace({ labPath }: LabWorkspaceProps) {
  return (
    <div className="lab-workspace">
      <iframe
        src={workspaceUrl(labPath)}
        title="VS Code Editor"
        className="lab-workspace__iframe"
        allow="clipboard-read; clipboard-write; fullscreen"
      />
    </div>
  );
}
