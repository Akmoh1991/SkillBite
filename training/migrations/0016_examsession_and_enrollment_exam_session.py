from django.conf import settings
from django.db import migrations, models
import django.db.models.deletion


class Migration(migrations.Migration):

    dependencies = [
        ('training', '0015_enrollmentrequest_part_attempts'),
        migrations.swappable_dependency(settings.AUTH_USER_MODEL),
    ]

    operations = [
        migrations.CreateModel(
            name='ExamSession',
            fields=[
                ('id', models.BigAutoField(auto_created=True, primary_key=True, serialize=False, verbose_name='ID')),
                ('exam_date', models.DateTimeField(verbose_name='موعد الاختبار')),
                ('exam_code_hash', models.CharField(blank=True, default='', max_length=128, verbose_name='هاش كود دخول الاختبار')),
                ('is_active', models.BooleanField(default=True, verbose_name='نشطة')),
                ('created_at', models.DateTimeField(auto_now_add=True, verbose_name='تاريخ الإنشاء')),
                ('created_by', models.ForeignKey(on_delete=django.db.models.deletion.CASCADE, related_name='created_exam_sessions', to=settings.AUTH_USER_MODEL, verbose_name='أنشئت بواسطة')),
                ('exam_template', models.ForeignKey(blank=True, null=True, on_delete=django.db.models.deletion.SET_NULL, related_name='exam_sessions', to='training.examtemplate', verbose_name='قالب الاختبار')),
                ('program', models.ForeignKey(on_delete=django.db.models.deletion.CASCADE, related_name='exam_sessions', to='training.program', verbose_name='البرنامج')),
            ],
            options={
                'verbose_name': 'جلسة اختبار',
                'verbose_name_plural': 'جلسات الاختبارات',
                'ordering': ['exam_date', 'id'],
            },
        ),
        migrations.AddField(
            model_name='enrollmentrequest',
            name='exam_session',
            field=models.ForeignKey(blank=True, null=True, on_delete=django.db.models.deletion.SET_NULL, related_name='enrollments', to='training.examsession', verbose_name='جلسة الاختبار'),
        ),
    ]
