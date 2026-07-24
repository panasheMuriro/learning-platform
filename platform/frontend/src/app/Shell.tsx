import { useCourseOutline, useProgress } from "@/api/content";
import type { CourseOutline, ModuleOutline, Progress } from "@/api/content";
import { ApplicationLayout } from "@canonical/react-components";
import type { ReactNode } from "react";
import { useMemo, useState } from "react";
import { Link, useLocation } from "react-router-dom";
import "./Shell.css";

interface ShellProps {
  children: ReactNode;
}

/** Extracts the courseId from the URL path (e.g. /courses/juju-terraform/...). */
function useCourseIdFromPath(): string | undefined {
  const { pathname } = useLocation();
  const match = pathname.match(/^\/courses\/([^/]+)/);
  return match?.[1];
}

export function Shell({ children }: ShellProps) {
  const courseId = useCourseIdFromPath();
  const { data: outline } = useCourseOutline(courseId ?? "");
  const { data: progress } = useProgress(courseId ?? "");

  const sideNav =
    courseId && outline ? (
      <CourseSidebar
        courseId={courseId}
        outline={outline}
        progress={progress}
      />
    ) : (
      <nav className="course-sidebar" aria-label="Main navigation">
        <Link to="/" className="course-sidebar__back">
          ← All courses
        </Link>
      </nav>
    );

  return (
    <ApplicationLayout
      sideNavigation={sideNav}
      logo={
        <Link to="/" className="shell__logo">
          🎓 {outline?.title ?? "Course Platform"}
        </Link>
      }
    >
      {children}
    </ApplicationLayout>
  );
}

function CourseSidebar({
  courseId,
  outline,
  progress,
}: {
  courseId: string;
  outline: CourseOutline;
  progress?: Progress;
}) {
  const { pathname } = useLocation();
  const [expanded, setExpanded] = useState<Set<string>>(
    () => new Set(outline.modules.map((m) => m.id)),
  );

  const toggleModule = (id: string) => {
    setExpanded((prev) => {
      const next = new Set(prev);
      if (next.has(id)) next.delete(id);
      else next.add(id);
      return next;
    });
  };

  const stats = useMemo(() => {
    let total = 0;
    let done = 0;
    for (const mod of outline.modules) {
      const modProgress = progress?.modules.find((p) => p.moduleId === mod.id);
      const modTotal =
        mod.lectures.length + mod.labs.length + (mod.quiz ? 1 : 0);
      const modDone =
        (modProgress?.lecturesCompleted.length ?? 0) +
        (modProgress?.labsCompleted.length ?? 0) +
        (modProgress?.quizPassed ? 1 : 0);
      total += modTotal;
      done += modDone;
    }
    return {
      total,
      done,
      pct: total > 0 ? Math.round((done / total) * 100) : 0,
    };
  }, [outline, progress]);

  return (
    <nav className="course-sidebar" aria-label="Course navigation">
      <Link to="/" className="course-sidebar__back">
        ← All courses
      </Link>

      <div className="course-sidebar__title">{outline.title}</div>

      <div className="course-sidebar__overall">
        <div className="course-sidebar__overall-top">
          <span>{stats.pct}% Complete</span>
          <span>
            {stats.done}/{stats.total} Items
          </span>
        </div>
        <div className="course-sidebar__progress-bar">
          <div
            className="course-sidebar__progress-fill"
            style={{ width: `${stats.pct}%` }}
          />
        </div>
      </div>

      <div className="course-sidebar__modules">
        {outline.modules.map((mod) => (
          <ModuleSection
            key={mod.id}
            courseId={courseId}
            module={mod}
            progress={progress?.modules.find((p) => p.moduleId === mod.id)}
            expanded={expanded.has(mod.id)}
            onToggle={() => toggleModule(mod.id)}
            pathname={pathname}
          />
        ))}
      </div>
    </nav>
  );
}

function ModuleSection({
  courseId,
  module,
  progress,
  expanded,
  onToggle,
  pathname,
}: {
  courseId: string;
  module: ModuleOutline;
  progress?: Progress["modules"][number];
  expanded: boolean;
  onToggle: () => void;
  pathname: string;
}) {
  const total =
    module.lectures.length + module.labs.length + (module.quiz ? 1 : 0);
  const done =
    (progress?.lecturesCompleted.length ?? 0) +
    (progress?.labsCompleted.length ?? 0) +
    (progress?.quizPassed ? 1 : 0);
  const pct = total > 0 ? Math.round((done / total) * 100) : 0;

  return (
    <div
      className={`course-sidebar__module ${
        expanded ? "course-sidebar__module--expanded" : ""
      }`}
    >
      <button
        type="button"
        className="course-sidebar__module-header"
        onClick={onToggle}
        aria-expanded={expanded}
      >
        <span className="course-sidebar__module-chevron">
          {expanded ? "▼" : "▶"}
        </span>
        <span className="course-sidebar__module-title">{module.title}</span>
        <ProgressRing pct={pct} />
      </button>

      {expanded && (
        <ul className="course-sidebar__items">
          {module.lectures.map((lec) => {
            const href = `/courses/${courseId}/modules/${module.id}/lectures/${lec.id}`;
            const done = progress?.lecturesCompleted.includes(lec.id) ?? false;
            return (
              <NavItem
                key={lec.id}
                href={href}
                icon={<PlayIcon />}
                label={lec.title}
                done={done}
                active={pathname === href}
              />
            );
          })}
          {module.quiz && (
            <NavItem
              href={`/courses/${courseId}/modules/${module.id}/quiz`}
              icon={<QuizIcon />}
              label="Quiz"
              done={progress?.quizPassed ?? false}
              active={
                pathname === `/courses/${courseId}/modules/${module.id}/quiz`
              }
            />
          )}
          {module.labs.map((lab) => {
            const href = `/courses/${courseId}/modules/${module.id}/labs/${lab.id}`;
            const done = progress?.labsCompleted.includes(lab.id) ?? false;
            return (
              <NavItem
                key={lab.id}
                href={href}
                icon={<LabIcon />}
                label={lab.title}
                done={done}
                active={pathname === href}
              />
            );
          })}
        </ul>
      )}
    </div>
  );
}

function NavItem({
  href,
  icon,
  label,
  done,
  active,
}: {
  href: string;
  icon: ReactNode;
  label: string;
  done: boolean;
  active: boolean;
}) {
  return (
    <li>
      <Link
        to={href}
        className={`course-sidebar__item ${
          active ? "course-sidebar__item--active" : ""
        }`}
      >
        <span className="course-sidebar__item-icon">{icon}</span>
        <span className="course-sidebar__item-label">{label}</span>
        <span
          className={`course-sidebar__check ${
            done ? "course-sidebar__check--done" : ""
          }`}
          aria-hidden="true"
        >
          {done && <CheckIcon />}
        </span>
      </Link>
    </li>
  );
}

function ProgressRing({ pct }: { pct: number }) {
  const radius = 10;
  const circumference = 2 * Math.PI * radius;
  const dash = (pct / 100) * circumference;
  return (
    <svg
      width="24"
      height="24"
      viewBox="0 0 24 24"
      className="course-sidebar__ring"
      role="img"
      aria-label={`${pct}% complete`}
    >
      <circle
        cx="12"
        cy="12"
        r={radius}
        fill="none"
        stroke="rgba(255, 255, 255, 0.15)"
        strokeWidth="3"
      />
      <circle
        cx="12"
        cy="12"
        r={radius}
        fill="none"
        stroke="#0e8420"
        strokeWidth="3"
        strokeDasharray={`${dash} ${circumference}`}
        transform="rotate(-90 12 12)"
      />
      <text
        x="12"
        y="15"
        textAnchor="middle"
        fontSize="7"
        fill="currentColor"
        fontWeight="600"
      >
        {pct}%
      </text>
    </svg>
  );
}

function PlayIcon() {
  return (
    <svg
      width="14"
      height="14"
      viewBox="0 0 24 24"
      fill="currentColor"
      aria-hidden="true"
    >
      <path d="M8 5v14l11-7z" />
    </svg>
  );
}

function LabIcon() {
  return (
    <svg
      width="14"
      height="14"
      viewBox="0 0 24 24"
      fill="none"
      stroke="currentColor"
      strokeWidth="2"
      aria-hidden="true"
    >
      <path d="M9 3v6m6-6v6m-9 4h12M6 21h12a2 2 0 0 0 2-2v-6H4v6a2 2 0 0 0 2 2z" />
    </svg>
  );
}

function QuizIcon() {
  return (
    <svg
      width="14"
      height="14"
      viewBox="0 0 24 24"
      fill="none"
      stroke="currentColor"
      strokeWidth="2"
      aria-hidden="true"
    >
      <circle cx="12" cy="12" r="10" />
      <path d="M9.09 9a3 3 0 0 1 5.83 1c0 2-3 3-3 3" />
      <line x1="12" y1="17" x2="12.01" y2="17" />
    </svg>
  );
}

function CheckIcon() {
  return (
    <svg
      width="12"
      height="12"
      viewBox="0 0 24 24"
      fill="none"
      stroke="currentColor"
      strokeWidth="3"
      aria-hidden="true"
    >
      <polyline points="20 6 9 17 4 12" />
    </svg>
  );
}
