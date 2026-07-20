import { submitQuiz, useQuiz } from "@/api/content";
import type { QuizQuestion } from "@/api/content";
import {
  Button,
  Card,
  Notification,
  NotificationSeverity,
} from "@canonical/react-components";
import { useState } from "react";
import { useParams } from "react-router-dom";
import "./Quiz.css";

export function QuizPage() {
  const { moduleId = "" } = useParams();
  const { data: quiz, isLoading, error } = useQuiz(moduleId);
  const [answers, setAnswers] = useState<Record<string, string | string[]>>({});
  const [result, setResult] = useState<{
    score: number;
    passed: boolean;
  } | null>(null);
  const [submitting, setSubmitting] = useState(false);

  if (isLoading) return <div className="course-content">Loading quiz…</div>;
  if (error || !quiz)
    return <div className="course-content">Failed to load quiz.</div>;

  const handleAnswer = (qId: string, value: string | string[]) => {
    setAnswers((prev) => ({ ...prev, [qId]: value }));
  };

  const handleSubmit = async () => {
    setSubmitting(true);
    try {
      const res = await submitQuiz(moduleId, answers);
      setResult(res);
    } finally {
      setSubmitting(false);
    }
  };

  const allAnswered = quiz.questions.every((q) => {
    const a = answers[q.id];
    return Array.isArray(a) ? a.length > 0 : a !== undefined && a !== "";
  });

  return (
    <div className="course-content quiz">
      <h1 className="p-heading--1">Module Quiz</h1>

      {result && (
        <Notification
          severity={
            result.passed
              ? NotificationSeverity.POSITIVE
              : NotificationSeverity.NEGATIVE
          }
          title={
            result.passed
              ? `Passed — ${result.score}%`
              : `Failed — ${result.score}%`
          }
        />
      )}

      {quiz.questions.map((q, i) => (
        <Card key={q.id} className="quiz__question">
          <p className="p-text-paragraph quiz__prompt">
            <strong>{i + 1}.</strong> {q.prompt}
          </p>
          <QuizQuestionInput
            question={q}
            answer={answers[q.id]}
            onAnswer={(v) => handleAnswer(q.id, v)}
            revealed={!!result}
          />
          {result && q.explanation && (
            <p className="quiz__explanation">💡 {q.explanation}</p>
          )}
        </Card>
      ))}

      <Button
        appearance="positive"
        onClick={handleSubmit}
        disabled={!allAnswered || submitting}
        loading={submitting}
      >
        Submit Quiz
      </Button>
    </div>
  );
}

interface QuizQuestionInputProps {
  question: QuizQuestion;
  answer: string | string[] | undefined;
  onAnswer: (value: string | string[]) => void;
  revealed: boolean;
}

function QuizQuestionInput({
  question,
  answer,
  onAnswer,
  revealed,
}: QuizQuestionInputProps) {
  if (question.type === "text-answer") {
    return (
      <input
        type="text"
        className="p-form-control"
        value={(typeof answer === "string" ? answer : "") as string}
        onChange={(e) => onAnswer(e.target.value)}
        disabled={revealed}
        placeholder="Type your answer…"
      />
    );
  }

  if (question.type === "single-choice" && question.options) {
    return (
      <div className="quiz__options">
        {question.options.map((opt) => (
          <label key={opt} className="p-radio">
            <input
              type="radio"
              className="p-radio__input"
              name={question.id}
              checked={answer === opt}
              onChange={() => onAnswer(opt)}
              disabled={revealed}
            />
            <span className="p-radio__label">{opt}</span>
          </label>
        ))}
      </div>
    );
  }

  if (question.type === "multi-choice" && question.options) {
    return (
      <div className="quiz__options">
        {question.options.map((opt) => {
          const selected = Array.isArray(answer) ? answer.includes(opt) : false;
          return (
            <label key={opt} className="p-checkbox">
              <input
                type="checkbox"
                className="p-checkbox__input"
                checked={selected}
                onChange={() => {
                  const current = Array.isArray(answer) ? answer : [];
                  onAnswer(
                    selected
                      ? current.filter((o) => o !== opt)
                      : [...current, opt],
                  );
                }}
                disabled={revealed}
              />
              <span className="p-checkbox__label">{opt}</span>
            </label>
          );
        })}
      </div>
    );
  }

  return null;
}
