import { submitQuiz, useQuiz } from "@/api/content";
import type { QuizQuestion } from "@/api/content";
import { Button, Card, Field } from "@canonical/react-components";
import { useState } from "react";
import { useParams } from "react-router-dom";
import "./Quiz.css";

export function QuizPage() {
  const { courseId = "", moduleId = "" } = useParams();
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

interface QuizQuestionInputProps {
  question: QuizQuestion;
  answer: string | string[] | undefined;
  onChange: (value: string | string[]) => void;
  revealed: boolean;
}

function QuizQuestionInput({
  question,
  answer,
  onChange,
  revealed,
}: QuizQuestionInputProps) {
  if (question.type === "text-answer") {
    return (
      <Field label="Your answer">
        <input
          type="text"
          className="quiz__text-input"
          disabled={revealed}
          placeholder="Type your answer…"
          value={(answer as string) ?? ""}
          onChange={(e) => onChange(e.target.value)}
        />
      </Field>
    );
  }

  if (question.type === "single-choice" && question.options) {
    return (
      <Field label="Select one">
        <div className="quiz__choices">
          {question.options.map((opt) => (
            <label key={opt} className="quiz__choice">
              <input
                type="radio"
                name={question.id}
                disabled={revealed}
                checked={answer === opt}
                onChange={() => onChange(opt)}
              />
              {opt}
            </label>
          ))}
        </div>
      </Field>
    );
  }

  if (question.type === "multi-choice" && question.options) {
    const selected = (answer as string[]) ?? [];
    return (
      <Field label="Select all that apply">
        <div className="quiz__choices">
          {question.options.map((opt) => (
            <label key={opt} className="quiz__choice">
              <input
                type="checkbox"
                disabled={revealed}
                checked={selected.includes(opt)}
                onChange={(e) => {
                  if (e.target.checked) {
                    onChange([...selected, opt]);
                  } else {
                    onChange(selected.filter((s) => s !== opt));
                  }
                }}
              />
              {opt}
            </label>
          ))}
        </div>
      </Field>
    );
  }

  return null;
}
