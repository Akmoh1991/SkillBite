from django.core.management.base import BaseCommand
from django.db import transaction
from django.db.models import Q

from training.models import Program
from training.program_catalog import COURSE_ATTENDANCE_PROGRAMS, PROGRAM_HIERARCHY


class Command(BaseCommand):
    help = 'Seed missing Technical/Solar programs from the predefined hierarchy.'

    def add_arguments(self, parser):
        parser.add_argument(
            '--apply',
            action='store_true',
            help='Write changes to DB. Without this flag, command runs in dry-run mode.',
        )
        parser.add_argument(
            '--outcome-type',
            choices=[Program.OutcomeType.CERTIFICATE, Program.OutcomeType.PASS_CARD],
            default=Program.OutcomeType.CERTIFICATE,
            help='Outcome type for newly created programs (default: CERTIFICATE).',
        )
        parser.add_argument(
            '--only',
            choices=['TECHNICAL_EXAM', 'SOLAR_POWER_EXAM', 'COURSE_ATTENDANCE'],
            help='Seed one category only.',
        )
        parser.add_argument(
            '--activate-existing',
            action='store_true',
            help='If set, existing matched programs will be activated (`is_active=True`).',
        )

    def handle(self, *args, **options):
        apply_changes = bool(options['apply'])
        outcome_type = options['outcome_type']
        only_category = options.get('only')
        activate_existing = bool(options['activate_existing'])

        created_count = 0
        existing_count = 0
        activated_count = 0

        self.stdout.write(self.style.WARNING(
            'Running in APPLY mode.' if apply_changes else 'Running in DRY-RUN mode. No DB writes will be made.'
        ))

        with transaction.atomic():
            target_categories = ['TECHNICAL_EXAM', 'SOLAR_POWER_EXAM', 'COURSE_ATTENDANCE']
            if only_category:
                target_categories = [only_category]

            for category_code in target_categories:
                if category_code == 'COURSE_ATTENDANCE':
                    self.stdout.write(f'\nCategory: {category_code}')
                    for item in COURSE_ATTENDANCE_PROGRAMS:
                        title_en = (item.get('en') or '').strip()
                        title_ar = (item.get('ar') or '').strip()
                        if not title_en and not title_ar:
                            continue
                        existing, created, activated = self._upsert_program(
                            category_code=category_code,
                            subcategory_code='',
                            main_exam_en='In person course',
                            title_en=title_en,
                            title_ar=title_ar,
                            outcome_type=outcome_type,
                            apply_changes=apply_changes,
                            activate_existing=activate_existing,
                        )
                        existing_count += existing
                        created_count += created
                        activated_count += activated
                    continue

                subcategories = PROGRAM_HIERARCHY.get(category_code, [])
                self.stdout.write(f'\nCategory: {category_code}')
                for subcategory in subcategories:
                    main_exam_en = subcategory.get('main_exam_en', '').strip()
                    self.stdout.write(f'  Main exam: {main_exam_en}')
                    program_rows = subcategory.get('programs', [])
                    tertiary_levels = subcategory.get('tertiary_levels') or []
                    if tertiary_levels:
                        program_rows = []
                        for tertiary in tertiary_levels:
                            program_rows.extend(tertiary.get('programs', []))

                    for item in program_rows:
                        title_en = (item.get('en') or '').strip()
                        title_ar = (item.get('ar') or '').strip()
                        if not title_en and not title_ar:
                            continue
                        existing, created, activated = self._upsert_program(
                            category_code=category_code,
                            subcategory_code=subcategory.get('code', ''),
                            main_exam_en=main_exam_en,
                            title_en=title_en,
                            title_ar=title_ar,
                            outcome_type=outcome_type,
                            apply_changes=apply_changes,
                            activate_existing=activate_existing,
                        )
                        existing_count += existing
                        created_count += created
                        activated_count += activated

            if not apply_changes:
                transaction.set_rollback(True)

        self.stdout.write('\nSummary:')
        self.stdout.write(f'  Existing matches: {existing_count}')
        self.stdout.write(f'  Created: {created_count}')
        self.stdout.write(f'  Activated existing: {activated_count}')
        self.stdout.write(self.style.SUCCESS('Done.'))

    def _upsert_program(
        self,
        *,
        category_code,
        subcategory_code,
        main_exam_en,
        title_en,
        title_ar,
        outcome_type,
        apply_changes,
        activate_existing,
    ):
        q = Q()
        for name in (title_en, title_ar):
            if not name:
                continue
            q |= (
                Q(title__iexact=name)
                | Q(title_en__iexact=name)
                | Q(title_ar__iexact=name)
            )

        existing = Program.objects.filter(q).order_by('id').first() if q else None
        if existing:
            was_inactive = activate_existing and not existing.is_active
            update_fields = []
            if subcategory_code and (getattr(existing, 'program_subcategory', '') or '') != subcategory_code:
                existing.program_subcategory = subcategory_code
                update_fields.append('program_subcategory')
            if was_inactive:
                self.stdout.write(f'    [activate] {existing.id} :: {existing.title}')
                if apply_changes:
                    existing.is_active = True
                    update_fields.append('is_active')
            if apply_changes and update_fields:
                existing.save(update_fields=update_fields)
            if was_inactive:
                return 1, 0, 1
            self.stdout.write(f'    [exists] {existing.id} :: {existing.title}')
            return 1, 0, 0

        self.stdout.write(f'    [create] {title_en or title_ar}')
        if apply_changes:
            Program.objects.create(
                title=title_ar or title_en,
                title_ar=title_ar,
                title_en=title_en,
                description=f'{main_exam_en} - {title_en or title_ar}',
                program_type=category_code,
                program_subcategory=subcategory_code,
                outcome_type=outcome_type,
                requires_approval=True,
                requires_payment=True,
                is_active=True,
            )
        return 0, 1, 0
