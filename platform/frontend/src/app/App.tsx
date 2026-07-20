import { Shell } from "@/app/Shell";
import { LabPage } from "@/features/lab/LabPage";
import { LecturePage } from "@/features/lecture/LecturePage";
import { DashboardPage } from "@/features/progress/DashboardPage";
import { QuizPage } from "@/features/quiz/QuizPage";
import { Navigate, Route, Routes } from "react-router-dom";

export function App() {
  return (
    <Shell>
      <Routes>
        <Route path="/" element={<DashboardPage />} />
        <Route
          path="/modules/:moduleId/lectures/:lectureId"
          element={<LecturePage />}
        />
        <Route path="/modules/:moduleId/quiz" element={<QuizPage />} />
        <Route path="/modules/:moduleId/labs/:labId" element={<LabPage />} />
        <Route path="*" element={<Navigate to="/" replace />} />
      </Routes>
    </Shell>
  );
}
