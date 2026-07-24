import { Shell } from "@/app/Shell";
import { CourseCatalogPage } from "@/features/catalog/CourseCatalogPage";
import { LabPage } from "@/features/lab/LabPage";
import { LecturePage } from "@/features/lecture/LecturePage";
import { DashboardPage } from "@/features/progress/DashboardPage";
import { QuizPage } from "@/features/quiz/QuizPage";
import { Navigate, Route, Routes } from "react-router-dom";

export function App() {
  return (
    <Shell>
      <Routes>
        <Route path="/" element={<CourseCatalogPage />} />
        <Route path="/courses/:courseId" element={<DashboardPage />} />
        <Route
          path="/courses/:courseId/modules/:moduleId/lectures/:lectureId"
          element={<LecturePage />}
        />
        <Route
          path="/courses/:courseId/modules/:moduleId/quiz"
          element={<QuizPage />}
        />
        <Route
          path="/courses/:courseId/modules/:moduleId/labs/:labId"
          element={<LabPage />}
        />
        <Route path="*" element={<Navigate to="/" replace />} />
      </Routes>
    </Shell>
  );
}
