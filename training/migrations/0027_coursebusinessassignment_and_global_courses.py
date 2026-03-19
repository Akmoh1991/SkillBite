from django.conf import settings
from django.db import migrations, models
import django.db.models.deletion


class Migration(migrations.Migration):

    dependencies = [
        ('accounts', '0008_remove_contractordocument_owner_and_more'),
        ('training', '0026_remove_courseassignmentrule_unique_course_rule_per_job_title_and_more'),
    ]

    operations = [
        migrations.AlterField(
            model_name='course',
            name='business',
            field=models.ForeignKey(
                blank=True,
                null=True,
                on_delete=django.db.models.deletion.CASCADE,
                related_name='courses',
                to='accounts.businesstenant',
                verbose_name='Business',
            ),
        ),
        migrations.CreateModel(
            name='CourseBusinessAssignment',
            fields=[
                ('id', models.BigAutoField(auto_created=True, primary_key=True, serialize=False, verbose_name='ID')),
                ('created_at', models.DateTimeField(auto_now_add=True, verbose_name='Created at')),
                ('assigned_by', models.ForeignKey(blank=True, null=True, on_delete=django.db.models.deletion.SET_NULL, related_name='course_business_assignments', to=settings.AUTH_USER_MODEL, verbose_name='Assigned by')),
                ('business', models.ForeignKey(on_delete=django.db.models.deletion.CASCADE, related_name='assigned_courses', to='accounts.businesstenant', verbose_name='Business')),
                ('course', models.ForeignKey(on_delete=django.db.models.deletion.CASCADE, related_name='business_assignments', to='training.course', verbose_name='Course')),
            ],
            options={
                'verbose_name': 'Course business assignment',
                'verbose_name_plural': 'Course business assignments',
                'ordering': ['course__title', 'business__name', 'id'],
            },
        ),
        migrations.AddConstraint(
            model_name='coursebusinessassignment',
            constraint=models.UniqueConstraint(fields=('course', 'business'), name='unique_course_business_assignment'),
        ),
    ]
