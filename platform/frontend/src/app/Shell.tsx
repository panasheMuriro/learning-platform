import { useCourseOutline } from "@/api/content";
import { ApplicationLayout } from "@canonical/react-components";
import type { ReactNode } from "react";
import { Link, useParams } from "react-router-dom";

interface ShellProps {
  children: ReactNode;
}

export function Shell({ children }: ShellProps) {
  const { courseId } = useParams();

  // Only fetch the outline if we're inside a course route (courseId present)
  const { data: outline } = useCourseOutline(courseId ?? "");

  // Build nav items for the SideNavigation.
  // When no course is selected (catalog page), show just the "All Courses" link.
  const navItems = outline
    ? [
        {
          items: [
            {
              label: "Dashboard",
              href: `/courses/${courseId}`,
              icon: "home",
            },
            ...outline.modules.flatMap((mod) => [
              {
                label: mod.title,
                href: `/courses/${courseId}/modules/${mod.id}/lectures/${mod.lectures[0]?.id ?? ""}`,
                icon: "book",
              },
              ...mod.lectures.map((lec) => ({
                label: lec.title,
                href: `/courses/${courseId}/modules/${mod.id}/lectures/${lec.id}`,
              })),
              ...(mod.quiz
                ? [
                    {
                      label: "Quiz",
                      href: `/courses/${courseId}/modules/${mod.id}/quiz`,
                    },
                  ]
                : []),
              ...mod.labs.map((lab) => ({
                label: lab.title,
                href: `/courses/${courseId}/modules/${mod.id}/labs/${lab.id}`,
              })),
            ]),
          ],
        },
      ]
    : [
        {
          items: [
            {
              label: "All Courses",
              href: "/",
              icon: "home",
            },
          ],
        },
      ];

  return (
    <ApplicationLayout
      navItems={navItems}
      navLinkComponent={Link}
      logo={
        <span style={{ fontSize: "1.5rem" }}>
          🎓 {outline?.title ?? "Course Platform"}
        </span>
      }
    >
      {children}
    </ApplicationLayout>
  );
}
