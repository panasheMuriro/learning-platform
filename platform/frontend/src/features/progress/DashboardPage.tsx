import { useCourseOutline, useProgress } from "@/api/content";
import type { ModuleOutline, Progress } from "@/api/content";
import { Card, Col, Row, Strip } from "@canonical/react-components";
import { Link } from "react-router-dom";
import "./DashboardPage.css";

export function DashboardPage() {
  const { data: outline, isLoading } = useCourseOutline();
  const { data: progress } = useProgress();

  if (isLoading) return <div className="course-content">Loading…</div>;
  if (!outline)
    return <div className="course-content">Failed to load course.</div>;

  const totalLectures = outline.modules.reduce(
    (n, m) => n + m.lectures.length,
    0,
  );
  const totalLabs = outline.modules.reduce((n, m) => n + m.labs.length, 0);

  return (
    <Strip>
      <div className="course-content">
        <Row>
          <Col size={12}>
            <h1 className="p-heading--1">{outline.title}</h1>
            <p className="p-text-paragraph">
              Learn Juju and Terraform together — hands-on, in your browser.
            </p>
          </Col>
        </Row>

        <Row className="dashboard__stats">
          <Col size={4}>
            <Card>
              <div className="dashboard__stat">
                <span className="dashboard__stat-num">
                  {outline.modules.length}
                </span>
                <span className="dashboard__stat-label">Modules</span>
              </div>
            </Card>
          </Col>
          <Col size={4}>
            <Card>
              <div className="dashboard__stat">
                <span className="dashboard__stat-num">{totalLectures}</span>
                <span className="dashboard__stat-label">Lectures</span>
              </div>
            </Card>
          </Col>
          <Col size={4}>
            <Card>
              <div className="dashboard__stat">
                <span className="dashboard__stat-num">{totalLabs}</span>
                <span className="dashboard__stat-label">Labs</span>
              </div>
            </Card>
          </Col>
        </Row>

        <div className="dashboard__modules">
          {outline.modules.map((mod, idx) => (
            <ModuleCard
              key={mod.id}
              module={mod}
              index={idx}
              progress={progress?.modules.find((p) => p.moduleId === mod.id)}
            />
          ))}
        </div>
      </div>
    </Strip>
  );
}

interface ModuleCardProps {
  module: ModuleOutline;
  index: number;
  progress?: Progress["modules"][number];
}

function ModuleCard({ module, index, progress }: ModuleCardProps) {
  const lecturesDone = progress?.lecturesCompleted.length ?? 0;
  const labsDone = progress?.labsCompleted.length ?? 0;
  const totalItems =
    module.lectures.length + module.labs.length + (module.quiz ? 1 : 0);
  const doneItems = lecturesDone + labsDone + (progress?.quizPassed ? 1 : 0);
  const pct = totalItems > 0 ? Math.round((doneItems / totalItems) * 100) : 0;

  return (
    <Link
      to={`/modules/${module.id}/lectures/${module.lectures[0]?.id ?? ""}`}
      className="module-card"
    >
      <Card>
        <div className="module-card__header">
          <span className="module-card__number">{index + 1}</span>
          <h3 className="p-heading--4 module-card__title">{module.title}</h3>
          {pct === 100 && (
            <span className="module-card__status module-card__status--done">
              ✓
            </span>
          )}
          {doneItems > 0 && pct < 100 && (
            <span className="module-card__status module-card__status--progress">
              ●
            </span>
          )}
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
    </Link>
  );
}
