import type { LabTask as LabTaskType, TaskResult } from "@/api/content";
import { Button } from "@canonical/react-components";
import { useState } from "react";
import ReactMarkdown from "react-markdown";
import rehypeHighlight from "rehype-highlight";
import rehypeSanitize from "rehype-sanitize";
import remarkGfm from "remark-gfm";
import "./LabTask.css";

interface LabTaskProps {
  task: LabTaskType;
  taskNumber: number;
  totalTasks: number;
  taskResult?: TaskResult;
  completed: boolean;
  onCheck: () => void;
  onNext: () => void;
  checking: boolean;
}

export function LabTask({
  task,
  taskNumber,
  totalTasks,
  taskResult,
  completed,
  onCheck,
  onNext,
  checking,
}: LabTaskProps) {
  const [revealedHints, setRevealedHints] = useState(0);
  const [solutionOpen, setSolutionOpen] = useState(false);
  const [confirmSolution, setConfirmSolution] = useState(false);

  const showNextHint = () => {
    if (task.hints && revealedHints < task.hints.length) {
      setRevealedHints(revealedHints + 1);
    }
  };

  const handleRevealSolution = () => {
    if (!confirmSolution) {
      setConfirmSolution(true);
      return;
    }
    setSolutionOpen(true);
    setConfirmSolution(false);
  };

  return (
    <div className="lab-task">
      <div className="lab-task__header">
        <span className="lab-task__number">
          Task {taskNumber} of {totalTasks}
        </span>
        <h2 className="lab-task__title">{task.title}</h2>
      </div>

      <div className="lab-task__instructions">
        <ReactMarkdown
          remarkPlugins={[remarkGfm]}
          rehypePlugins={[rehypeSanitize, rehypeHighlight]}
        >
          {task.instructions}
        </ReactMarkdown>
      </div>

      {task.hints && task.hints.length > 0 && (
        <div className="lab-task__hints">
          <h3>Hints</h3>
          {revealedHints === 0 ? (
            <Button
              type="button"
              appearance="neutral"
              onClick={showNextHint}
              className="lab-task__hint-btn"
            >
              💡 Show hint 1
            </Button>
          ) : (
            <ol className="lab-task__hint-list">
              {task.hints.slice(0, revealedHints).map((hint) => (
                <li key={hint} className="lab-task__hint">
                  <ReactMarkdown
                    remarkPlugins={[remarkGfm]}
                    rehypePlugins={[rehypeSanitize, rehypeHighlight]}
                  >
                    {hint}
                  </ReactMarkdown>
                </li>
              ))}
            </ol>
          )}
          {task.hints.length > 0 &&
            revealedHints < task.hints.length &&
            revealedHints > 0 && (
              <Button
                type="button"
                appearance="neutral"
                onClick={showNextHint}
                className="lab-task__hint-btn"
              >
                💡 Show hint {revealedHints + 1}
              </Button>
            )}
        </div>
      )}

      {task.solution && (
        <div className="lab-task__solution">
          {!solutionOpen ? (
            <>
              {confirmSolution && (
                <div className="lab-task__solution-warning">
                  ⚠️ Revealing the solution will skip the learning. Continue?
                </div>
              )}
              <Button
                type="button"
                appearance="neutral"
                onClick={handleRevealSolution}
                className="lab-task__solution-btn"
              >
                {confirmSolution ? "Yes, show solution" : "🔓 Show solution"}
              </Button>
            </>
          ) : (
            <div className="lab-task__solution-content">
              <h3>Solution</h3>
              <ReactMarkdown
                remarkPlugins={[remarkGfm]}
                rehypePlugins={[rehypeSanitize, rehypeHighlight]}
              >
                {task.solution}
              </ReactMarkdown>
            </div>
          )}
        </div>
      )}

      <div className="lab-task__actions">
        <Button
          type="button"
          appearance="positive"
          onClick={onCheck}
          disabled={checking || completed}
          className="lab-task__check-btn"
        >
          {checking ? "Checking…" : completed ? "✅ Passed" : "✓ Check task"}
        </Button>
        {completed && (
          <Button
            type="button"
            appearance="positive"
            onClick={onNext}
            className="lab-task__next-btn"
          >
            Next task →
          </Button>
        )}
      </div>

      {taskResult && !taskResult.passed && (
        <div className="lab-task__feedback lab-task__feedback--fail">
          <strong>❌ {taskResult.name}</strong>
          <p>{taskResult.message}</p>
        </div>
      )}
      {completed && !taskResult?.passed && (
        <div className="lab-task__feedback lab-task__feedback--pass">
          ✅ Task passed
        </div>
      )}
    </div>
  );
}
