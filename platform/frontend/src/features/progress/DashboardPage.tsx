import {
  resetCourseProgress,
  useCourseOutline,
  useProgress,
} from "@/api/content";
import type { ModuleOutline, Progress } from "@/api/content";
import { Icon } from "@/components/Icon";
import { Button, Card } from "@canonical/react-components";
import { useQueryClient } from "@tanstack/react-query";
import { useState } from "react";
import { Link, useParams } from "react-router-dom";
import "./DashboardPage.css";

export function DashboardPage() {
  const { courseId = "" } = useParams();
  const queryClient = useQueryClient();
  const { data: outline, isLoading } = useCourseOutline(courseId);
  const { data: progress } = useProgress(courseId);
  const [resetting, setResetting] = useState(false);

  if (isLoading) {
    return (
      <div className="course-content">
        <div className="dashboard__loading">
          <Icon name="spinner" className="dashboard__spinner" size={24} />
          <span>Loading course outline...</span>
        </div>
      </div>
    );
  }
  if (!outline) {
    return (
      <div className="course-content">
        <div className="p-notification--negative">
          <div className="p-notification__content">
            <h5 className="p-notification__title">Failed to load course</h5>
            <p className="p-notification__message">Course outline could not be loaded.</p>
          </div>
        </div>
      </div>
    );
  }

  const totalLectures = outline.modules.reduce(
    (n, m) => n + m.lectures.length,
    0,
  );
  const totalLabs = outline.modules.reduce((n, m) => n + m.labs.length, 0);
  const totalQuizzes = outline.modules.reduce((n, m) => n + (m.quiz ? 1 : 0), 0);

  let totalDone = 0;
  for (const mod of outline.modules) {
    const modProgress = progress?.modules.find((p) => p.moduleId === mod.id);
    totalDone +=
      (modProgress?.lecturesCompleted.length ?? 0) +
      (modProgress?.labsCompleted.length ?? 0) +
      (modProgress?.quizPassed ? 1 : 0);
  }
  const totalAllItems = totalLectures + totalLabs + totalQuizzes;
  const overallPct = totalAllItems > 0 ? Math.round((totalDone / totalAllItems) * 100) : 0;

  const handleReset = async () => {
    if (
      !window.confirm(
        "Are you sure you want to reset all progress for this course? This cannot be undone.",
      )
    ) {
      return;
    }
    setResetting(true);
    try {
      const updated = await resetCourseProgress(courseId);
      queryClient.setQueryData(["progress", courseId], updated);
    } finally {
      setResetting(false);
    }
  };

  return (
    <div className="dashboard">
      <div className="dashboard__hero">
        <div className="dashboard__hero-header">
          <div>
            <div className="dashboard__track-badge">Enterprise Track</div>
            <h1 className="dashboard__title">{outline.title}</h1>
          </div>
          <Button
            type="button"
            appearance="negative"
            disabled={resetting}
            onClick={handleReset}
            className="dashboard__reset-btn"
          >
            {resetting ? "Resetting…" : "Reset Progress"}
          </Button>
        </div>
        
        <p className="dashboard__subtitle">
          Hands-on curriculum with interactive uniter labs, live controller grading, and concept evaluations.
        </p>

        <div className="dashboard__stats-grid">
          <div className="dashboard__stat-card">
            <div className="dashboard__stat-icon-wrap">
              <Icon name="topic" size={20} />
            </div>
            <div className="dashboard__stat-content">
              <span className="dashboard__stat-num">{outline.modules.length}</span>
              <span className="dashboard__stat-label">Modules</span>
            </div>
          </div>

          <div className="dashboard__stat-card">
            <div className="dashboard__stat-icon-wrap">
              <Icon name="book" size={20} />
            </div>
            <div className="dashboard__stat-content">
              <span className="dashboard__stat-num">{totalLectures}</span>
              <span className="dashboard__stat-label">Lectures</span>
            </div>
          </div>

          <div className="dashboard__stat-card">
            <div className="dashboard__stat-icon-wrap">
              <Icon name="terminal" size={20} />
            </div>
            <div className="dashboard__stat-content">
              <span className="dashboard__stat-num">{totalLabs}</span>
              <span className="dashboard__stat-label">Hands-On Labs</span>
            </div>
          </div>

          <div className="dashboard__stat-card dashboard__stat-card--progress">
            <div className="dashboard__stat-content">
              <div className="dashboard__stat-progress-head">
                <span className="dashboard__stat-label">Overall Progress</span>
                <span className="dashboard__stat-pct">{overallPct}%</span>
              </div>
              <div className="dashboard__overall-bar">
                <div
                  className="dashboard__overall-fill"
                  style={{ width: `${overallPct}%` }}
                />
              </div>
            </div>
          </div>
        </div>
      </div>

      <div className="dashboard__section-header">
        <h2 className="dashboard__section-title">Course Modules</h2>
        <span className="dashboard__section-count">{outline.modules.length} modules</span>
      </div>

      <div className="dashboard__modules">
        {outline.modules.map((mod, idx) => (
          <ModuleOverviewCard
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

interface ModuleOverviewCardProps {
  module: ModuleOutline;
  index: number;
  courseId: string;
  progress?: Progress["modules"][number];
}

function ModuleOverviewCard({ module, index, courseId, progress }: ModuleOverviewCardProps) {
  const lecturesDone = progress?.lecturesCompleted.length ?? 0;
  const labsDone = progress?.labsCompleted.length ?? 0;
  const quizPassed = progress?.quizPassed ?? false;
  
  const totalItems =
    module.lectures.length + module.labs.length + (module.quiz ? 1 : 0);
  const doneItems = lecturesDone + labsDone + (quizPassed ? 1 : 0);
  const pct = totalItems > 0 ? Math.round((doneItems / totalItems) * 100) : 0;
  
  const firstLectureUrl = `/courses/${courseId}/modules/${module.id}/lectures/${module.lectures[0]?.id ?? ""}`;

  return (
    <Card className="module-card">
      <div className="module-card__header">
        <div className="module-card__index-badge">
          Module {String(index + 1).padStart(2, "0")}
        </div>
        <div className="module-card__pct-badge">
          {pct === 100 ? (
            <span className="status-badge status-badge--success">Completed</span>
          ) : (
            <span>{pct}% done</span>
          )}
        </div>
      </div>

      <div className="module-card__body">
        <Link to={firstLectureUrl} className="module-card__title">
          {module.title}
        </Link>
        
        <div className="module-card__progress">
          <div
            className="module-card__progress-bar"
            style={{ width: `${pct}%` }}
          />
        </div>

        <div className="module-card__meta-tags">
          <span className="module-card__tag">
            <Icon name="book" size={13} /> {module.lectures.length} Lectures ({lecturesDone}/{module.lectures.length})
          </span>
          <span className="module-card__tag">
            <Icon name="terminal" size={13} /> {module.labs.length} Labs ({labsDone}/{module.labs.length})
          </span>
          {module.quiz && (
            <span className="module-card__tag">
              <Icon name="help" size={13} /> Assessment {quizPassed ? "✓" : "—"}
            </span>
          )}
        </div>
      </div>

      <div className="module-card__footer">
        <Link to={firstLectureUrl} className="module-card__action-btn">
          Start Module <Icon name="arrow-right" size={14} />
        </Link>
      </div>
    </Card>
  );
}
