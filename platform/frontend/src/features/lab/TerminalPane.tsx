import { terminalWsUrl } from "@/api/content";
import { FitAddon } from "@xterm/addon-fit";
import { Terminal } from "@xterm/xterm";
import { useEffect, useRef } from "react";
import "@xterm/xterm/css/xterm.css";
import "./TerminalPane.css";

interface TerminalPaneProps {
  /** Lab working directory path. When provided, the terminal shell starts in
   * this directory. When undefined, the terminal waits (no shell spawned). */
  labPath?: string;
}

export function TerminalPane({ labPath }: TerminalPaneProps) {
  const containerRef = useRef<HTMLDivElement>(null);
  const termRef = useRef<Terminal | null>(null);
  const wsRef = useRef<WebSocket | null>(null);
  const resizeHandlerRef = useRef<(() => void) | null>(null);

  useEffect(() => {
    // Don't connect until the lab path is known (after seeding completes).
    if (!labPath || !containerRef.current) return;

    const container = containerRef.current;

    // Defer initialization to next frame so the container has dimensions.
    // xterm.js throws if term.open() is called on a zero-size element.
    const raf = requestAnimationFrame(() => {
      const term = new Terminal({
        fontSize: 14,
        fontFamily: "monospace",
        cursorBlink: true,
        theme: {
          background: "#1e1e1e",
          foreground: "#d4d4d4",
        },
      });
      const fitAddon = new FitAddon();
      term.loadAddon(fitAddon);
      term.open(container);
      fitAddon.fit();
      termRef.current = term;

      // Pass the lab path as a query param so the backend PTY starts in the
      // lab working directory.
      const wsUrl = `${terminalWsUrl()}?path=${encodeURIComponent(labPath)}`;
      const ws = new WebSocket(wsUrl);
      wsRef.current = ws;

      ws.onopen = () => {
        term.writeln("\x1b[32mConnected to lab terminal.\x1b[0m");
        ws.send(
          JSON.stringify({
            type: "resize",
            cols: term.cols,
            rows: term.rows,
          }),
        );
      };

      ws.onmessage = (event) => {
        if (typeof event.data === "string") {
          term.write(event.data);
        }
      };

      ws.onerror = () => {
        term.writeln("\x1b[31mTerminal connection error.\x1b[0m");
      };

      ws.onclose = () => {
        term.writeln("\x1b[33mTerminal disconnected.\x1b[0m");
      };

      term.onData((data: string) => {
        if (ws.readyState === WebSocket.OPEN) {
          ws.send(data);
        }
      });

      const handleResize = () => {
        fitAddon.fit();
        if (ws.readyState === WebSocket.OPEN) {
          ws.send(
            JSON.stringify({
              type: "resize",
              cols: term.cols,
              rows: term.rows,
            }),
          );
        }
      };
      window.addEventListener("resize", handleResize);
      resizeHandlerRef.current = handleResize;
    });

    return () => {
      cancelAnimationFrame(raf);
      if (resizeHandlerRef.current) {
        window.removeEventListener("resize", resizeHandlerRef.current);
        resizeHandlerRef.current = null;
      }
      wsRef.current?.close();
      termRef.current?.dispose();
    };
  }, [labPath]);

  if (!labPath) {
    return (
      <div className="terminal-pane">
        <div className="lab-workspace__loading">Preparing terminal…</div>
      </div>
    );
  }

  return (
    <div
      ref={containerRef}
      className="terminal-pane"
      style={{ width: "100%", height: "100%" }}
    />
  );
}
