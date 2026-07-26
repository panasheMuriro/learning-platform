import { Markdown } from "@/components/Markdown";

interface LectureViewerProps {
  markdown: string;
}

export function LectureViewer({ markdown }: LectureViewerProps) {
  return (
    <div className="lecture-viewer">
      <Markdown>{markdown}</Markdown>
    </div>
  );
}
