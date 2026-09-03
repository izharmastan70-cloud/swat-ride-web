'use client';

import React, { useState } from 'react';
import {
  MessageSquare,
  Send,
  CheckCircle2,
  ShieldCheck,
  Phone,
  Mail,
  MapPin,
  AlertTriangle,
} from 'lucide-react';
import { Breadcrumbs } from '@/components/layout/Breadcrumbs';
import { Input } from '@/components/ui/Input';
import { Textarea } from '@/components/ui/Textarea';
import { Button } from '@/components/ui/Button';
import { cn } from '@/lib/utils';

type FeedbackType = 'complaint' | 'suggestion' | 'service_feedback' | 'technical_issue' | 'safety_issue';

export default function ContactFeedbackPage() {
  const [feedbackType, setFeedbackType] = useState<FeedbackType>('service_feedback');
  const [name, setName] = useState('');
  const [phoneOrEmail, setPhoneOrEmail] = useState('');
  const [subject, setSubject] = useState('');
  const [message, setMessage] = useState('');
  const [isSubmitting, setIsSubmitting] = useState(false);
  const [submitted, setSubmitted] = useState(false);
  const [error, setError] = useState('');

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    if (!name.trim() || !phoneOrEmail.trim() || !message.trim()) {
      setError('Please fill out your name, contact details, and feedback message.');
      return;
    }
    setError('');
    setIsSubmitting(true);

    // Simulate secure submission without exposing internal moderation/admin workflows
    setTimeout(() => {
      setIsSubmitting(false);
      setSubmitted(true);
      setName('');
      setPhoneOrEmail('');
      setSubject('');
      setMessage('');
    }, 900);
  };

  return (
    <div className="relative py-12 sm:py-16">
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
        <Breadcrumbs
          items={[
            { label: 'Support & Help', href: '/help' },
            { label: 'Feedback & Contact Support' },
          ]}
        />

        {/* Hero */}
        <div className="text-center max-w-3xl mx-auto mb-16 space-y-4">
          <span className="inline-flex items-center gap-2 px-3.5 py-1.5 rounded-full bg-swat-950/80 border border-swat-500/40 text-xs font-semibold text-swat-300">
            <MessageSquare className="w-4 h-4 text-swat-400" />
            <span>SWAT RIDE • Public Feedback & Support Desk</span>
          </span>

          <h1 className="text-4xl sm:text-5xl font-black text-white tracking-tight">
            We Value Your Voice in Swat
          </h1>

          <p className="text-base text-mountain-300 leading-relaxed">
            Submit a complaint, suggestion, service feedback, technical issue, or safety report. Our Mingora Support Desk reviews all submissions within 2–4 hours.
          </p>
        </div>

        <div className="grid grid-cols-1 lg:grid-cols-12 gap-12 max-w-6xl mx-auto items-start">
          {/* Left Form Col */}
          <div className="lg:col-span-7">
            <div className="p-8 rounded-3xl bg-mountain-900/80 border border-mountain-800 shadow-glass-lg space-y-6">
              <div className="border-b border-mountain-800 pb-4">
                <h2 className="text-xl font-bold text-white">Submit Public Feedback / Ticket</h2>
                <p className="text-xs text-mountain-400 mt-1">
                  Select your feedback category below to route your message to the right regional team.
                </p>
              </div>

              {submitted ? (
                <div className="p-8 rounded-2xl bg-swat-950/80 border border-swat-500/40 text-center space-y-4">
                  <CheckCircle2 className="w-12 h-12 text-swat-400 mx-auto" />
                  <h3 className="text-2xl font-bold text-white">Feedback Received!</h3>
                  <p className="text-sm text-mountain-200 max-w-md mx-auto leading-relaxed">
                    Thank you for writing to SWAT RIDE. Your reference ticket has been logged securely with our Mingora Support Desk. A support representative will follow up via your contact number if further details are required.
                  </p>
                  <button
                    onClick={() => setSubmitted(false)}
                    className="mt-4 px-6 py-2.5 rounded-xl bg-swat-600 hover:bg-swat-500 text-white text-xs font-bold transition-all"
                  >
                    Submit Another Message
                  </button>
                </div>
              ) : (
                <form onSubmit={handleSubmit} className="space-y-6">
                  {/* Category Selector Buttons */}
                  <div>
                    <label className="block text-xs font-semibold text-mountain-300 uppercase mb-2">
                      1. Feedback Category
                    </label>
                    <div className="grid grid-cols-2 sm:grid-cols-3 gap-2">
                      {[
                        { id: 'service_feedback', label: 'Service Feedback' },
                        { id: 'suggestion', label: 'Suggestion' },
                        { id: 'complaint', label: 'Complaint' },
                        { id: 'technical_issue', label: 'Technical Issue' },
                        { id: 'safety_issue', label: 'Safety Issue' },
                      ].map((item) => {
                        const isSelected = feedbackType === item.id;
                        return (
                          <button
                            type="button"
                            key={item.id}
                            onClick={() => setFeedbackType(item.id as FeedbackType)}
                            className={cn(
                              'p-3 rounded-xl border text-xs font-semibold text-center transition-all',
                              isSelected
                                ? 'bg-swat-600 text-white border-swat-500 shadow-md'
                                : 'bg-mountain-950/80 border-mountain-800 text-mountain-300 hover:text-white'
                            )}
                          >
                            {item.label}
                          </button>
                        );
                      })}
                    </div>
                  </div>

                  {/* Name & Contact Details */}
                  <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
                    <Input
                      label="2. Your Name"
                      placeholder="e.g. Sher Ali"
                      value={name}
                      onChange={(e) => setName(e.target.value)}
                      required
                    />
                    <Input
                      label="3. Phone or Email"
                      placeholder="0300-XXXXXXX / name@domain.pk"
                      value={phoneOrEmail}
                      onChange={(e) => setPhoneOrEmail(e.target.value)}
                      required
                    />
                  </div>

                  {/* Subject */}
                  <Input
                    label="4. Subject (Optional)"
                    placeholder="e.g. Fare estimate inquiry / Kalam Jeep praise"
                    value={subject}
                    onChange={(e) => setSubject(e.target.value)}
                  />

                  {/* Message */}
                  <Textarea
                    label="5. Your Message / Details"
                    placeholder="Describe your feedback, suggestion, or issue in detail..."
                    rows={5}
                    value={message}
                    onChange={(e) => setMessage(e.target.value)}
                    required
                  />

                  {error && (
                    <div className="p-3 rounded-xl bg-red-950/80 border border-red-500/40 text-xs text-red-300 font-medium">
                      {error}
                    </div>
                  )}

                  <div className="pt-2 flex items-center justify-between">
                    <span className="text-[11px] text-mountain-400">
                      🔒 Submissions are protected by KPK privacy standards.
                    </span>
                    <Button
                      type="submit"
                      variant="primary"
                      size="md"
                      isLoading={isSubmitting}
                      icon={<Send className="w-4 h-4" />}
                    >
                      Submit Feedback
                    </Button>
                  </div>
                </form>
              )}
            </div>
          </div>

          {/* Right Col: Regional Contact Info & Headquarters */}
          <div className="lg:col-span-5 space-y-6">
            <div className="p-8 rounded-3xl bg-mountain-900/80 border border-mountain-800 space-y-6 shadow-glass-sm">
              <h3 className="text-xl font-bold text-white">Mingora Headquarters & Support Hub</h3>

              <div className="space-y-4 text-sm text-mountain-300">
                <div className="flex items-start gap-3">
                  <MapPin className="w-5 h-5 text-swat-400 shrink-0 mt-0.5" />
                  <div>
                    <p className="font-semibold text-white">Swat Regional Office</p>
                    <p className="text-xs text-mountain-400 mt-0.5">
                      Main Saidu Sharif Road, near Swat Museum, Mingora, District Swat, Khyber Pakhtunkhwa, Pakistan.
                    </p>
                  </div>
                </div>

                <div className="flex items-start gap-3">
                  <Phone className="w-5 h-5 text-swat-400 shrink-0 mt-0.5" />
                  <div>
                    <p className="font-semibold text-white">24/7 Swat Support Line</p>
                    <p className="text-xs text-mountain-400 mt-0.5">
                      0300-SWATRIDE (Local Assistance & Driver Help)
                    </p>
                  </div>
                </div>

                <div className="flex items-start gap-3">
                  <Mail className="w-5 h-5 text-swat-400 shrink-0 mt-0.5" />
                  <div>
                    <p className="font-semibold text-white">Official Support Email</p>
                    <p className="text-xs text-mountain-400 mt-0.5">
                      support@swatride.pk • safety@swatride.pk
                    </p>
                  </div>
                </div>
              </div>

              <div className="p-4 rounded-2xl bg-mountain-950 border border-mountain-800 text-xs text-mountain-300 space-y-1">
                <div className="font-bold text-white">Emergency SOS Note</div>
                <p>
                  For immediate physical safety emergencies during a ride, always use the red SOS button inside your active SWAT RIDE app session.
                </p>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
}
