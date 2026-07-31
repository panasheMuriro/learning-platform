import { submitLectureQuiz } from "@/api/content";
import type { QuizQuestion } from "@/api/content";
import { Icon } from "@/components/Icon";
import { QuizQuestionInput } from "@/components/QuizQuestionInput";
import { Button, Card } from "@canonical/react-components";
import { useState } from "react";
import "./LectureQuiz.css";

interface LectureQuizProps {
  courseId: string;
  moduleId: string;
  lectureId: string;
  questions: QuizQuestion[];
}

export function LectureQuiz({
  courseId,
  moduleId,
  lectureId,
  questions,
}: LectureQuizProps) {
  const [answers, setAnswers] = useState<Record<string, string | string[]>>({});
  const [result, setResult] = useState<{
    score: number;
    passed: boolean;
  } | null>(null);
  const [submitting, setSubmitting] = useState(false);

  const setAnswer = (questionId: string, value: string | string[]) => {
    setAnswers((prev) => ({ ...prev, [questionId]: value }));
  };

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setSubmitting(true);
    try {
      const res = await submitLectureQuiz(
        courseId,
        moduleId,
        lectureId,
        answers,
      );
      setResult(res);
    } finally {
      setSubmitting(false);
    }
  };

  const handleReset = () => {
    setAnswers({});
    setResult(null);
  };

  return (
    <div className="lecture-quiz">
      <h2 className="lecture-quiz__title">Quick Check</h2>
      <form onSubmit={handleSubmit}>
        {questions.map((q, i) => (
          <Card key={q.id} className="lecture-quiz__question">
            <p className="lecture-quiz__prompt">
              {i + 1}. {q.prompt}
            </p>
            <QuizQuestionInput
              question={q}
              answer={answers[q.id]}
              onChange={(val) => setAnswer(q.id, val)}
              revealed={!!result}
            />
            {result && q.explanation && (
              <p className="lecture-quiz__explanation">
                <Icon name="help" size={14} />
                {q.explanation}
              </p>
            )}
          </Card>
        ))}
        {result && (
          <div
            className={`lecture-quiz__result ${result.passed ? "lecture-quiz__result--pass" : "lecture-quiz__result--fail"}`}
          >
            <Icon name={result.passed ? "success" : "error"} size={14} />
            Score: {result.score}% — {result.passed ? "Passed" : "Failed"}
          </div>
        )}
        <div className="lecture-quiz__actions">
          <Button type="submit" appearance="positive" disabled={submitting}>
            {submitting ? "Submitting…" : "Submit Answers"}
          </Button>
          {result && (
            <Button type="button" appearance="neutral" onClick={handleReset}>
              Try Again
            </Button>
          )}
        </div>
      </form>
    </div>
  );
}
