import { useCourses } from "@/api/content";
import { Icon, type IconName } from "@/components/Icon";
import { Card } from "@canonical/react-components";
import { Link } from "react-router-dom";
import "./CourseCatalogPage.css";

export function CourseCatalogPage() {
  const { data: courses, isLoading, error } = useCourses();

  if (isLoading) return <div className="course-content">Loading courses…</div>;
  if (error)
    return <div className="course-content">Failed to load courses.</div>;

  return (
    <div className="catalog">
      <div className="catalog__hero">
        <h1>Course Platform</h1>
        <p className="catalog__subtitle">
          Hands-on courses that run entirely on your machine.
        </p>
      </div>
      <div className="catalog__grid">
        {courses?.map((course) => (
          <Link
            key={course.id}
            to={`/courses/${course.slug}`}
            className="catalog__card-link"
          >
            <Card className="catalog__card">
              <Icon
                name={(course.icon as IconName) || "book"}
                className="catalog__card-icon"
                size={32}
              />
              <h2 className="catalog__card-title">{course.title}</h2>
              <p className="catalog__card-summary">{course.summary}</p>
              {course.version && (
                <span className="catalog__card-version">v{course.version}</span>
              )}
            </Card>
          </Link>
        ))}
        {courses?.length === 0 && (
          <p className="catalog__empty">No courses available yet.</p>
        )}
      </div>
    </div>
  );
}
