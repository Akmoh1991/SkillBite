from django.conf import settings
from django.db import migrations, models
import django.db.models.deletion


class Migration(migrations.Migration):

    dependencies = [
        ('accounts', '0007_businesstenant_jobtitle_employeeprofile_and_more'),
        ('training', '0023_coursecontentitem_video_file'),
        migrations.swappable_dependency(settings.AUTH_USER_MODEL),
    ]

    operations = [
        migrations.AddField(
            model_name='examtemplate',
            name='business',
            field=models.ForeignKey(
                blank=True,
                null=True,
                on_delete=django.db.models.deletion.CASCADE,
                related_name='exam_templates',
                to='accounts.businesstenant',
                verbose_name='Business',
            ),
        ),
        migrations.AddField(
            model_name='course',
            name='exam_template',
            field=models.ForeignKey(
                blank=True,
                null=True,
                on_delete=django.db.models.deletion.SET_NULL,
                related_name='courses',
                to='training.examtemplate',
                verbose_name='Exam template',
            ),
        ),
        migrations.CreateModel(
            name='CourseExamSession',
            fields=[
                ('id', models.BigAutoField(auto_created=True, primary_key=True, serialize=False, verbose_name='ID')),
                ('exam_date', models.DateTimeField(verbose_name='Exam date')),
                ('access_code', models.CharField(blank=True, default='', max_length=32, verbose_name='Access code')),
                ('is_active', models.BooleanField(default=True, verbose_name='Active')),
                ('created_at', models.DateTimeField(auto_now_add=True, verbose_name='Created at')),
                ('course', models.ForeignKey(on_delete=django.db.models.deletion.CASCADE, related_name='exam_sessions', to='training.course', verbose_name='Course')),
                ('created_by', models.ForeignKey(on_delete=django.db.models.deletion.CASCADE, related_name='created_course_exam_sessions', to=settings.AUTH_USER_MODEL, verbose_name='Created by')),
                ('exam_template', models.ForeignKey(blank=True, null=True, on_delete=django.db.models.deletion.SET_NULL, related_name='course_sessions', to='training.examtemplate', verbose_name='Exam template')),
            ],
            options={
                'verbose_name': 'Course exam session',
                'verbose_name_plural': 'Course exam sessions',
                'ordering': ['-exam_date', '-id'],
            },
        ),
    ]
