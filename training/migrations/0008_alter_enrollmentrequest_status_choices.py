from django.db import migrations, models


class Migration(migrations.Migration):

    dependencies = [
        ('training', '0007_enrollment_renewal_fields'),
    ]

    operations = [
        migrations.AlterField(
            model_name='enrollmentrequest',
            name='status',
            field=models.CharField(
                choices=[
                    ('NEW_REQUEST', 'طلب جديد'),
                    ('REJECTED', 'مرفوض'),
                    ('INVOICE_ISSUED', 'فاتورة مصدرة'),
                    ('PAYMENT_VERIFICATION', 'التحقق مع عملية السداد'),
                    ('WAITING_EXAM_SCHEDULING', 'إنشاء موعد اختبار'),
                    ('EXAM_SCHEDULED', 'حجز موعد الاختبار'),
                    ('EXAM_CONFIRMED', 'الحضور لأداء الاختبار'),
                    ('IN_EXAM', 'جاري الاختبار'),
                    ('FAILED', 'لم يجتز الاختبار'),
                    ('CERTIFIED', 'شهادة مصدرة'),
                    ('COMPLETED_WITH_PASS_CARD', 'بطاقة اجتياز مصدرة'),
                ],
                default='NEW_REQUEST',
                max_length=40,
                verbose_name='حالة الطلب',
            ),
        ),
    ]
