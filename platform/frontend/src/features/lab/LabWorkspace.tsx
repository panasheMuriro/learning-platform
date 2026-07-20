import "./LabWorkspace.css";

interface LabWorkspaceProps {
  labId: string;
  moduleId: string;
}

// code-server URL — configurable via Vite env variable.
// - Dev: Vite proxy at /code-server/ → http://localhost:8081
// - Prod: set VITE_CODE_SERVER_URL to the code-server address (e.g. http://localhost:8081)
const CODE_SERVER_URL = import.meta.env.VITE_CODE_SERVER_URL || "/code-server/";

// code-server mounts the whole lab-root as /home/coder/project. Opening the
// lab's own subfolder (rather than the project root) means learners only
// ever see the files for the lab they're currently working on, not every
// other lab's starter files too.
function workspaceUrl(labId: string): string {
  const folder = `/home/coder/project/${labId}`;
  const separator = CODE_SERVER_URL.includes("?") ? "&" : "?";
  return `${CODE_SERVER_URL}${separator}folder=${encodeURIComponent(folder)}`;
}

export function LabWorkspace({ labId }: LabWorkspaceProps) {
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
