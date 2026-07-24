import { type FileEntry, listFiles, readFile, writeFile } from "@/api/content";
import { Button } from "@canonical/react-components";
import Editor from "@monaco-editor/react";
import { useCallback, useEffect, useState } from "react";
import { TerminalPane } from "./TerminalPane";
import "./LabWorkspace.css";

interface LabWorkspaceProps {
  labId: string;
  moduleId: string;
}

export function LabWorkspace({ labId }: LabWorkspaceProps) {
  const labPath = `/home/student/${labId}`;
  const [files, setFiles] = useState<FileEntry[]>([]);
  const [selectedFile, setSelectedFile] = useState<string | null>(null);
  const [fileContent, setFileContent] = useState<string>("");
  const [loading, setLoading] = useState(true);
  const [dirty, setDirty] = useState(false);
  const [saving, setSaving] = useState(false);

  const refreshFiles = useCallback(() => {
    listFiles(labPath)
      .then(setFiles)
      .catch(() => setFiles([]))
      .finally(() => setLoading(false));
  }, [labPath]);

  useEffect(() => {
    refreshFiles();
  }, [refreshFiles]);

  const handleSelectFile = async (path: string) => {
    if (dirty && selectedFile) {
      if (!confirm("You have unsaved changes. Discard them?")) return;
    }
    setSelectedFile(path);
    setDirty(false);
    const content = await readFile(path);
    setFileContent(content);
  };

  const handleEditorChange = (val: string | undefined) => {
    setFileContent(val ?? "");
    setDirty(true);
  };

  const handleSave = async () => {
    if (!selectedFile) return;
    setSaving(true);
    try {
      await writeFile(selectedFile, fileContent);
      setDirty(false);
    } finally {
      setSaving(false);
    }
  };

  // Ctrl+S to save
  useEffect(() => {
    const handleKeyDown = (e: KeyboardEvent) => {
      if ((e.ctrlKey || e.metaKey) && e.key === "s") {
        e.preventDefault();
        handleSave();
      }
    };
    window.addEventListener("keydown", handleKeyDown);
    return () => window.removeEventListener("keydown", handleKeyDown);
  });

  return (
    <div className="lab-workspace">
      <div className="lab-workspace__panes">
        {/* File tree pane */}
        <div className="lab-workspace__files">
          <div className="lab-workspace__pane-header">Files</div>
          <div className="lab-workspace__pane-body">
            {loading ? (
              <p className="lab-workspace__placeholder">Loading files…</p>
            ) : files.length === 0 ? (
              <p className="lab-workspace__placeholder">
                No files yet. Run <code>setup.sh</code> in the terminal to
                initialize the lab.
              </p>
            ) : (
              <ul className="lab-workspace__file-list">
                {files.map((f) => (
                  <li key={f.path}>
                    <button
                      type="button"
                      className={`lab-workspace__file-item ${selectedFile === f.path ? "lab-workspace__file-item--selected" : ""}`}
                      onClick={() => handleSelectFile(f.path)}
                    >
                      <span className="lab-workspace__file-icon">
                        {f.isDirectory ? "📁" : "📄"}
                      </span>
                      {f.name}
                    </button>
                  </li>
                ))}
              </ul>
            )}
          </div>
        </div>

        {/* Editor pane */}
        <div className="lab-workspace__editor">
          {selectedFile ? (
            <>
              <div className="lab-workspace__editor-toolbar">
                <span className="lab-workspace__filename">
                  {selectedFile.split("/").pop()}
                  {dirty && <span className="lab-workspace__dirty">●</span>}
                </span>
                <Button
                  type="button"
                  appearance="base"
                  onClick={handleSave}
                  disabled={!dirty || saving}
                >
                  {saving ? "Saving…" : "Save"}
                </Button>
              </div>
              <div className="lab-workspace__editor-body">
                <Editor
                  height="100%"
                  language={detectLanguage(selectedFile)}
                  value={fileContent}
                  onChange={handleEditorChange}
                  theme="vs-dark"
                  options={{
                    fontSize: 14,
                    minimap: { enabled: false },
                    automaticLayout: true,
                    tabSize: 2,
                    wordWrap: "on",
                  }}
                />
              </div>
            </>
          ) : (
            <div className="lab-workspace__placeholder-center">
              <p>Select a file from the tree to start editing</p>
            </div>
          )}
        </div>

        {/* Terminal pane */}
        <div className="lab-workspace__terminal">
          <div className="lab-workspace__pane-header lab-workspace__pane-header--terminal">
            Terminal
          </div>
          <div className="lab-workspace__terminal-body">
            <TerminalPane />
          </div>
        </div>
      </div>
    </div>
  );
}

function detectLanguage(filename: string): string {
  if (filename.endsWith(".tf")) return "hcl";
  if (filename.endsWith(".sh")) return "shell";
  if (filename.endsWith(".md")) return "markdown";
  if (filename.endsWith(".json")) return "json";
  if (filename.endsWith(".yaml") || filename.endsWith(".yml")) return "yaml";
  if (filename.endsWith(".go")) return "go";
  if (filename.endsWith(".ts") || filename.endsWith(".tsx"))
    return "typescript";
  if (filename.endsWith(".js") || filename.endsWith(".jsx"))
    return "javascript";
  return "plaintext";
}
