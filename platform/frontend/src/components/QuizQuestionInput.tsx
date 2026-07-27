import type { QuizQuestion } from "@/api/content";
import { Field } from "@canonical/react-components";

interface QuizQuestionInputProps {
  question: QuizQuestion;
  answer: string | string[] | undefined;
  onChange: (value: string | string[]) => void;
  revealed: boolean;
}

export function QuizQuestionInput({
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
