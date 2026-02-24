from __future__ import annotations

from django import forms


class PortalLoginForm(forms.Form):
    username = forms.CharField(label="اسم المستخدم", max_length=150)
    password = forms.CharField(label="كلمة المرور", widget=forms.PasswordInput)


class PortalOTPForm(forms.Form):
    code = forms.CharField(label="رمز التحقق", max_length=4)

    def clean_code(self):
        code = (self.cleaned_data.get("code") or "").strip()
        if not (len(code) == 4 and code.isdigit()):
            raise forms.ValidationError("الكود يجب أن يكون 4 أرقام")
        return code


class BulkMessageForm(forms.Form):
    body = forms.CharField(label="نص الرسالة", widget=forms.Textarea, max_length=2000)
    attachment = forms.FileField(label="مرفق", required=False)
    send_at = forms.DateTimeField(
        label="وقت الإرسال",
        required=False,
        input_formats=["%Y-%m-%dT%H:%M"],
    )


class FinanceSettingsForm(forms.Form):
    bank_name = forms.CharField(label="اسم البنك", required=False, max_length=120)
    account_name = forms.CharField(label="اسم الحساب", required=False, max_length=120)
    iban = forms.CharField(label="IBAN", required=False, max_length=34)
    qr_image = forms.FileField(label="QR", required=False)
