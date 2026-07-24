import { terminalWsUrl } from "@/api/content";
import { FitAddon } from "@xterm/addon-fit";
import { Terminal } from "@xterm/xterm";
import { useEffect, useRef } from "react";
import "@xterm/xterm/css/xterm.css";
import "./TerminalPane.css";

export function TerminalPane() {
  const containerRef = useRef<HTMLDivElement>(null);
  const termRef = useRef<Terminal | null>(null);
  const wsRef = useRef<WebSocket | null>(null);

  useEffect(() => {
    if (!containerRef.current) return;

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
    term.open(containerRef.current);
    fitAddon.fit();
    termRef.current = term;

    const ws = new WebSocket(terminalWsUrl());
    wsRef.current = ws;

    ws.onopen = () => {
      term.writeln("\x1b[32mConnected to lab terminal.\x1b[0m");
      // Send initial size
      ws.send(
        JSON.stringify({
          type: "resize",
          cols: term.cols,
          rows: term.rows,
        }),
      );
    };

    ws.onmessage = (event) => {
      // Messages from the backend are raw terminal output
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

    // Send user input to the backend
    term.onData((data: string) => {
      if (ws.readyState === WebSocket.OPEN) {
        ws.send(data);
      }
    });

    // Handle resize
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

    return () => {
      window.removeEventListener("resize", handleResize);
      ws.close();
      term.dispose();
    };
  }, []);

  return (
    <div
      ref={containerRef}
      className="terminal-pane"
      style={{ width: "100%", height: "100%" }}
    />
  );
}
