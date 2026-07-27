import { submitQuiz, useQuiz } from "@/api/content";
import { QuizQuestionInput } from "@/components/QuizQuestionInput";
import { Button, Card } from "@canonical/react-components";
import { useQueryClient } from "@tanstack/react-query";
import { useState } from "react";
import { useParams } from "react-router-dom";
import "./Quiz.css";

export function QuizPage() {
  const { courseId = "", moduleId = "" } = useParams();
  const queryClient = useQueryClient();
  const { data: quiz, isLoading, error } = useQuiz(courseId, moduleId);
  const [answers, setAnswers] = useState<Record<string, string | string[]>>({});
  const [result, setResult] = useState<{
    score: number;
    passed: boolean;
  } | null>(null);
  const [submitting, setSubmitting] = useState(false);

  if (isLoading) return <div className="course-content">Loading quiz…</div>;
  if (error || !quiz)
    return <div className="course-content">Failed to load quiz.</div>;

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setSubmitting(true);
    try {
      const res = await submitQuiz(courseId, moduleId, answers);
      setResult(res);
      // Refresh progress so the sidebar checkmark updates.
      await queryClient.invalidateQueries({ queryKey: ["progress", courseId] });
    } finally {
      setSubmitting(false);
    }
  };

  const setAnswer = (questionId: string, value: string | string[]) => {
    setAnswers((prev) => ({ ...prev, [questionId]: value }));
  };

  return (
    <div className="course-content quiz">
      <h1>Module Quiz</h1>
      <form onSubmit={handleSubmit}>
        {quiz.questions.map((q, i) => (
          <Card key={q.id} className="quiz__question">
            <p className="quiz__prompt">
              {i + 1}. {q.prompt}
            </p>
            <QuizQuestionInput
              question={q}
              answer={answers[q.id]}
              onChange={(val) => setAnswer(q.id, val)}
              revealed={!!result}
            />
            {result && q.explanation && (
              <p className="quiz__explanation">💡 {q.explanation}</p>
            )}
          </Card>
        ))}
        {result && (
          <div
            className={`quiz__result ${result.passed ? "quiz__result--pass" : "quiz__result--fail"}`}
          >
            Score: {result.score}% — {result.passed ? "Passed ✅" : "Failed ❌"}
          </div>
        )}
        <Button type="submit" appearance="positive" disabled={submitting}>
          {submitting ? "Submitting…" : "Submit Quiz"}
        </Button>
      </form>
    </div>
  );
}
