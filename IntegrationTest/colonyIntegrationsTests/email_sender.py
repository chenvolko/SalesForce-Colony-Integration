import smtplib
from email.mime.multipart import MIMEMultipart
from email.mime.text import MIMEText


def send_email(smtp_user, smtp_pass, recepient, message_title, message_body, is_html):
    smtp_address = 'smtp.office365.com'
    smtp_port = 587
    try:
        # Create message container - the correct MIME type is multipart/alternative.
        msg = MIMEMultipart('alternative')
        msg['Subject'] = message_title
        msg['From'] = smtp_user
        msg['To'] = recepient

        msg_text = MIMEText(message_body.encode('utf-8'), 'html', _charset='utf-8')
        msg.attach(msg_text)
        
        # Send the message via local SMTP server.
        smtp_session = smtplib.SMTP(smtp_address, smtp_port)
        smtp_session.ehlo()
        smtp_session.starttls()
        smtp_session.login(smtp_user, smtp_pass)

        # sendmail function takes 3 arguments: sender's address, recipient's address
        # and message to send - here it is sent as one string.
        response = smtp_session.send_message(msg)
        if response == {}:
            ans = True
        else: 
            ans = False            
        smtp_session.quit()            
        return ans
    except Exception:
        return False
