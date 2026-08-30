import { Button } from "@canonical/react-components";
import { type ReactNode, useCallback, useEffect, useId, useState } from "react";
import ReactMarkdown from "react-markdown";
import rehypeHighlight from "rehype-highlight";
import rehypeSanitize from "rehype-sanitize";
import remarkGfm from "remark-gfm";
import "./Markdown.css";

interface MarkdownProps {
  children: string;
  className?: string;
}

interface CodeBlockProps {
  children?: ReactNode;
  className?: string;
}

type MermaidAPI = typeof import("mermaid").default;

let mermaidModule: Promise<MermaidAPI> | null = null;

function loadMermaid(): Promise<MermaidAPI> {
  if (mermaidModule) return mermaidModule;
  mermaidModule = import("mermaid").then((m) => {
    const mermaid = m.default as MermaidAPI;
    mermaid.initialize({
      startOnLoad: false,
      theme: "default",
      securityLevel: "loose",
      suppressErrorRendering: true,
    });
    return mermaid;
  });
  return mermaidModule;
}

function MermaidDiagram({ source }: { source: string }) {
  const id = useId().replace(/[^a-zA-Z0-9]/g, "");
  const containerId = `mermaid-${id}`;
  const [svg, setSvg] = useState<string | null>(null);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    let cancelled = false;
    // Clean up any potential leftover mermaid error elements in body
    loadMermaid()
      .then(async (mermaid) => {
        try {
          const { svg } = await mermaid.render(containerId, source);
          if (!cancelled) {
            setSvg(svg);
            setError(null);
          }
        } catch (err) {
          // Remove any stray error svg that mermaid might append to DOM
          const errorEl = document.getElementById(containerId);
          if (errorEl) errorEl.remove();
          const dErrorEl = document.getElementById(`d${containerId}`);
          if (dErrorEl) dErrorEl.remove();

          if (!cancelled) setError(String(err));
        }
      })
      .catch((err) => {
        if (!cancelled) setError(String(err));
      });
    return () => {
      cancelled = true;
    };
  }, [containerId, source]);

  if (error) {
    return (
      <div className="mermaid-diagram mermaid-diagram--error">
        <pre>{error}</pre>
      </div>
    );
  }
  if (!svg) {
    return <div className="mermaid-diagram mermaid-diagram--loading" />;
  }
  return (
    <div
      className="mermaid-diagram"
      dangerouslySetInnerHTML={{ __html: svg }}
    />
  );
}

function InlineCode({
  className,
  children,
}: {
  className?: string;
  children?: ReactNode;
}) {
  const language = /language-(\S+)/.exec(className || "")?.[1];
  const source = extractText(children).trim();

  if (language === "mermaid" && source) {
    return <MermaidDiagram source={source} />;
  }

  return <code className={className}>{children}</code>;
}

function CodeBlock({ children, className }: CodeBlockProps) {
  const [copied, setCopied] = useState(false);

  const handleCopy = useCallback(async () => {
    const code = extractText(children);
    if (!code) return;
    try {
      await navigator.clipboard.writeText(code);
      setCopied(true);
      setTimeout(() => setCopied(false), 1500);
    } catch {
      // Ignore clipboard errors
    }
  }, [children]);

  return (
    <pre className={`markdown-pre ${className ?? ""}`}>
      <Button
        type="button"
        appearance="neutral"
        onClick={handleCopy}
        className="markdown-pre__copy"
        small
      >
        {copied ? "Copied" : "Copy"}
      </Button>
      {children}
    </pre>
  );
}

function extractText(node: ReactNode): string {
  if (typeof node === "string" || typeof node === "number") {
    return String(node);
  }
  if (Array.isArray(node)) {
    return node.map(extractText).join("");
  }
  if (node && typeof node === "object" && "props" in node) {
    return extractText(
      (node as { props?: { children?: ReactNode } }).props?.children,
    );
  }
  return "";
}

export function Markdown({ children, className }: MarkdownProps) {
  return (
    <div className={`markdown-body ${className ?? ""}`}>
      <ReactMarkdown
        remarkPlugins={[remarkGfm]}
        rehypePlugins={[rehypeSanitize, rehypeHighlight]}
        components={{
          pre: CodeBlock,
          code: InlineCode,
        }}
      >
        {children}
      </ReactMarkdown>
    </div>
  );
}
