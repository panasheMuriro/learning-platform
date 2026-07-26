import { Button } from "@canonical/react-components";
import { type ReactNode, useCallback, useState } from "react";
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
        }}
      >
        {children}
      </ReactMarkdown>
    </div>
  );
}
