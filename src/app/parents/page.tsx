import React from 'react';
import { notFound } from 'next/navigation';
import { PARTNER_ROLES } from '@/data/partners';
import { PartnerRoleView } from '@/components/partners/PartnerRoleView';

export default function ParentsPortalPage() {
  const role = PARTNER_ROLES.find((r) => r.slug === 'parents');
  if (!role) return notFound();
  return <PartnerRoleView role={role} />;
}
