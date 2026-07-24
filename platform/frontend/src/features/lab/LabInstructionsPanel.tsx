import ReactMarkdown from "react-markdown";
import rehypeHighlight from "rehype-highlight";
import rehypeSanitize from "rehype-sanitize";
import remarkGfm from "remark-gfm";

interface LabInstructionsPanelProps {
  markdown: string;
}

export function LabInstructionsPanel({ markdown }: LabInstructionsPanelProps) {
  return (
    <div className="lab-instructions">
      <ReactMarkdown
        remarkPlugins={[remarkGfm]}
        rehypePlugins={[rehypeSanitize, rehypeHighlight]}
      >
        {markdown}
      </ReactMarkdown>
    </div>
  );
}
