import { useCourseOutline, useProgress } from "@/api/content";
import type { ModuleOutline, Progress } from "@/api/content";
import { Card } from "@canonical/react-components";
import { Link, useParams } from "react-router-dom";
import "./DashboardPage.css";

export function DashboardPage() {
  const { courseId = "" } = useParams();
  const { data: outline, isLoading } = useCourseOutline(courseId);
  const { data: progress } = useProgress(courseId);

  if (isLoading) return <div className="course-content">Loading…</div>;
  if (!outline)
    return <div className="course-content">Failed to load course.</div>;

  const totalLectures = outline.modules.reduce(
    (n, m) => n + m.lectures.length,
    0,
  );
  const totalLabs = outline.modules.reduce((n, m) => n + m.labs.length, 0);

  return (
    <div className="dashboard">
      <div className="dashboard__hero">
        <h1>{outline.title}</h1>
        <p className="dashboard__subtitle">
          Hands-on learning — lectures, quizzes, and labs with auto-grading.
        </p>
        <div className="dashboard__stats">
          <Card className="dashboard__stat-card">
            <span className="dashboard__stat-num">
              {outline.modules.length}
            </span>
            <span className="dashboard__stat-label">Modules</span>
          </Card>
          <Card className="dashboard__stat-card">
            <span className="dashboard__stat-num">{totalLectures}</span>
            <span className="dashboard__stat-label">Lectures</span>
          </Card>
          <Card className="dashboard__stat-card">
            <span className="dashboard__stat-num">{totalLabs}</span>
            <span className="dashboard__stat-label">Labs</span>
          </Card>
        </div>
      </div>

      <div className="dashboard__modules">
        {outline.modules.map((mod, idx) => (
          <ModuleEvent
            key={mod.id}
            module={mod}
            index={idx}
            courseId={courseId}
            progress={progress?.modules.find((p) => p.moduleId === mod.id)}
          />
        ))}
      </div>
    </div>
  );
}

interface ModuleEventProps {
  module: ModuleOutline;
  index: number;
  courseId: string;
  progress?: Progress["modules"][number];
}

function ModuleEvent({ module, index, courseId, progress }: ModuleEventProps) {
  const lecturesDone = progress?.lecturesCompleted.length ?? 0;
  const labsDone = progress?.labsCompleted.length ?? 0;
  const totalItems =
    module.lectures.length + module.labs.length + (module.quiz ? 1 : 0);
  const doneItems = lecturesDone + labsDone + (progress?.quizPassed ? 1 : 0);
  const pct = totalItems > 0 ? Math.round((doneItems / totalItems) * 100) : 0;
  const firstLectureUrl = `/courses/${courseId}/modules/${module.id}/lectures/${module.lectures[0]?.id ?? ""}`;

  return (
    <Card className="module-card">
      <div className="module-card__header">
        <span className="module-card__number">{index + 1}</span>
        <Link to={firstLectureUrl} className="module-card__title">
          {module.title}
        </Link>
        {pct === 100 && <span className="module-card__done">✓</span>}
      </div>
      <div className="module-card__progress">
        <div
          className="module-card__progress-bar"
          style={{ width: `${pct}%` }}
        />
      </div>
      <div className="module-card__meta">
        <span>{pct}% complete</span>
        <span>
          {module.lectures.length} lectures · {module.labs.length} labs
          {module.quiz && " · quiz"}
        </span>
      </div>
    </Card>
  );
}
