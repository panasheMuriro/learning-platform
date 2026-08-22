import type { CourseOutline, ModuleItem } from "@/api/content";
import { Icon } from "@/components/Icon";
import { useMemo } from "react";
import { Link } from "react-router-dom";
import "./BottomNav.css";

export interface CourseNavTarget {
  type: "lecture" | "lab" | "quiz";
  id: string;
  title: string;
  moduleId: string;
  moduleTitle: string;
  href: string;
}

export function buildFlatCourseSequence(outline: CourseOutline, courseId: string): CourseNavTarget[] {
  const list: CourseNavTarget[] = [];
  for (const module of outline.modules) {
    let items: ModuleItem[];
    if (module.items && module.items.length > 0) {
      items = module.items;
    } else {
      items = module.lectures.map((l) => ({
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
    }

    for (const item of items) {
      const href =
        item.type === "lecture"
          ? `/courses/${courseId}/modules/${module.id}/lectures/${item.id}`
          : item.type === "lab"
            ? `/courses/${courseId}/modules/${module.id}/labs/${item.id}`
            : `/courses/${courseId}/modules/${module.id}/quiz`;

      list.push({
        type: item.type,
        id: item.id,
        title: item.title,
        moduleId: module.id,
        moduleTitle: module.title,
        href,
      });
    }
  }
  return list;
}

interface BottomNavProps {
  courseId: string;
  moduleId: string;
  currentItemType: "lecture" | "lab" | "quiz";
  currentItemId: string;
  outline: CourseOutline;
}

export function BottomNav({
  courseId,
  moduleId,
  currentItemType,
  currentItemId,
  outline,
}: BottomNavProps) {
  const { prevItem, nextItem } = useMemo(() => {
    const sequence = buildFlatCourseSequence(outline, courseId);
    const currentIndex = sequence.findIndex(
      (item) =>
        item.type === currentItemType &&
        item.moduleId === moduleId &&
        (currentItemType === "quiz" || item.id === currentItemId),
    );

    if (currentIndex === -1) {
      return { prevItem: null, nextItem: null };
    }

    return {
      prevItem: currentIndex > 0 ? sequence[currentIndex - 1] : null,
      nextItem: currentIndex < sequence.length - 1 ? sequence[currentIndex + 1] : null,
    };
  }, [outline, courseId, moduleId, currentItemType, currentItemId]);

  const getItemTypeLabel = (type: "lecture" | "lab" | "quiz") => {
    switch (type) {
      case "lecture":
        return "Lecture";
      case "lab":
        return "Lab";
      case "quiz":
        return "Quiz";
    }
  };

  if (!prevItem && !nextItem) {
    return null;
  }

  return (
    <nav className="bottom-nav" aria-label="Bottom navigation">
      {prevItem ? (
        <Link to={prevItem.href} className="bottom-nav__btn bottom-nav__btn--prev">
          <div className="bottom-nav__icon-box">
            <Icon name="arrow-left" size={16} />
          </div>
          <div className="bottom-nav__meta">
            <span className="bottom-nav__sub">
              Previous ({getItemTypeLabel(prevItem.type)})
            </span>
            <span className="bottom-nav__title">{prevItem.title}</span>
          </div>
        </Link>
      ) : (
        <div className="bottom-nav__spacer" />
      )}

      {nextItem ? (
        <Link to={nextItem.href} className="bottom-nav__btn bottom-nav__btn--next">
          <div className="bottom-nav__meta">
            <span className="bottom-nav__sub">
              Next ({getItemTypeLabel(nextItem.type)})
            </span>
            <span className="bottom-nav__title">{nextItem.title}</span>
          </div>
          <div className="bottom-nav__icon-box">
            <Icon name="arrow-right" size={16} />
          </div>
        </Link>
      ) : (
        <div className="bottom-nav__spacer" />
      )}
    </nav>
  );
}
