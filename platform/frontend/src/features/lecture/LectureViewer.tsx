import ReactMarkdown from "react-markdown";
import rehypeHighlight from "rehype-highlight";
import rehypeSanitize from "rehype-sanitize";
import remarkGfm from "remark-gfm";

interface LectureViewerProps {
  markdown: string;
}

export function LectureViewer({ markdown }: LectureViewerProps) {
  return (
    <div className="lecture-viewer">
      <ReactMarkdown
        remarkPlugins={[remarkGfm]}
        rehypePlugins={[rehypeSanitize, rehypeHighlight]}
      >
        {markdown}
      </ReactMarkdown>
    </div>
  );
}
