import {
  markLectureComplete,
  unmarkLab,
  unmarkLecture,
  unmarkQuiz,
  useCourseOutline,
  useProgress,
} from "@/api/content";
import type {
  CourseOutline,
  ModuleItem,
  ModuleOutline,
  Progress,
} from "@/api/content";
import { Icon } from "@/components/Icon";
import { ApplicationLayout, CheckboxInput } from "@canonical/react-components";
import { useQueryClient } from "@tanstack/react-query";
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
          <Icon name="arrow-left" className="icon--inline-start" light />
          All courses
        </Link>
      </nav>
    );

  return (
    <ApplicationLayout
      sideNavigation={sideNav}
      logo={
        <Link to="/" className="shell__logo">
          <Icon name="graduation" className="icon--inline-start" light />
          {outline?.title ?? "Course Platform"}
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
  const queryClient = useQueryClient();
  const [expanded, setExpanded] = useState<Set<string>>(() => new Set());

  const toggleModule = (id: string) => {
    setExpanded((prev) => {
      const next = new Set(prev);
      if (next.has(id)) next.delete(id);
      else next.add(id);
      return next;
    });
  };

  /** Toggle a lecture/lab/quiz completion. Calls the appropriate API and
   *  updates the progress cache so the sidebar reflects the change instantly. */
  const toggleItem = async (
    type: "lecture" | "lab" | "quiz",
    moduleId: string,
    itemId: string,
    currentlyDone: boolean,
  ) => {
    if (currentlyDone) {
      // Unmark
      let updated: Progress;
      if (type === "lecture") {
        updated = await unmarkLecture(courseId, moduleId, itemId);
      } else if (type === "lab") {
        updated = await unmarkLab(courseId, moduleId, itemId);
      } else {
        updated = await unmarkQuiz(courseId, moduleId);
      }
      queryClient.setQueryData(["progress", courseId], updated);
    } else {
      // Mark — only lectures have a mark endpoint; labs/quizzes are marked
      // implicitly by submitting. For toggle-on we still call the lecture
      // endpoint; labs and quizzes can only be toggled off from the sidebar.
      if (type === "lecture") {
        const updated = await markLectureComplete(courseId, moduleId, itemId);
        queryClient.setQueryData(["progress", courseId], updated);
      }
    }
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
        <Icon name="arrow-left" className="icon--inline-start" />
        All courses
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
            onToggleItem={toggleItem}
          />
        ))}
      </div>
    </nav>
  );
}

/** Build the default items list (lectures → quiz → labs) from the module's
 *  separate arrays. Used when the module has no explicit `items` array. */
function buildDefaultItems(module: ModuleOutline): ModuleItem[] {
  const items: ModuleItem[] = module.lectures.map((l) => ({
    type: "lecture" as const,
    id: l.id,
    title: l.title,
  }));
  if (module.quiz) {
    items.push({ type: "quiz", id: module.quiz.id, title: "Quiz" });
  }
  for (const lab of module.labs) {
    items.push({ type: "lab", id: lab.id, title: lab.title });
  }
  return items;
}

function ModuleSection({
  courseId,
  module,
  progress,
  expanded,
  onToggle,
  pathname,
  onToggleItem,
}: {
  courseId: string;
  module: ModuleOutline;
  progress?: Progress["modules"][number];
  expanded: boolean;
  onToggle: () => void;
  pathname: string;
  onToggleItem: (
    type: "lecture" | "lab" | "quiz",
    moduleId: string,
    itemId: string,
    currentlyDone: boolean,
  ) => void;
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
        <Icon
          name={expanded ? "chevron-down" : "chevron-right"}
          className="course-sidebar__module-chevron"
        />
        <span className="course-sidebar__module-title">{module.title}</span>
        <ProgressRing pct={pct} />
      </button>

      {expanded && (
        <ul className="course-sidebar__items">
          {(module.items ?? buildDefaultItems(module)).map((item) => {
            const href =
              item.type === "lecture"
                ? `/courses/${courseId}/modules/${module.id}/lectures/${item.id}`
                : item.type === "lab"
                  ? `/courses/${courseId}/modules/${module.id}/labs/${item.id}`
                  : `/courses/${courseId}/modules/${module.id}/quiz`;
            const done =
              item.type === "lecture"
                ? (progress?.lecturesCompleted.includes(item.id) ?? false)
                : item.type === "lab"
                  ? (progress?.labsCompleted.includes(item.id) ?? false)
                  : (progress?.quizPassed ?? false);
            const icon =
              item.type === "lecture" ? (
                <Icon name="topic" size={14} light />
              ) : item.type === "lab" ? (
                <Icon name="open-terminal" size={14} light />
              ) : (
                <Icon name="question" size={14} light />
              );
            return (
              <NavItem
                key={`${item.type}-${item.id}`}
                href={href}
                icon={icon}
                label={item.title}
                done={done}
                active={pathname === href}
                onToggle={() =>
                  onToggleItem(item.type, module.id, item.id, done)
                }
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
  onToggle,
}: {
  href: string;
  icon: ReactNode;
  label: string;
  done: boolean;
  active: boolean;
  onToggle: () => void;
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
        <CheckboxInput
          id={`${href}--toggle`}
          className="course-sidebar__check"
          label={done ? "Mark as incomplete" : "Mark as complete"}
          checked={done}
          onChange={onToggle}
        />
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
