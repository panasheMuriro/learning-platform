import { Markdown } from "@/components/Markdown";

interface LabInstructionsPanelProps {
  markdown: string;
}

export function LabInstructionsPanel({ markdown }: LabInstructionsPanelProps) {
  return (
    <div className="lab-instructions">
      <Markdown>{markdown}</Markdown>
    </div>
  );
}
