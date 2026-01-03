"""
SMTP Client for sending emails - COMPLETELY FIXED VERSION
"""
import smtplib
from email.mime.multipart import MIMEMultipart
from email.mime.text import MIMEText
from email.mime.base import MIMEBase
from email import encoders
from typing import List, Optional, Dict, Any
import base64
from email.utils import make_msgid

class SMTPClient:
    def __init__(self, smtp_host: str, smtp_port: int, 
                 username: str, password: str, use_tls: bool = True):
        self.smtp_host = smtp_host
        self.smtp_port = smtp_port
        self.username = username
        self.password = password
        self.use_tls = use_tls
        
    def send_email(self, to_email: List[str], subject: str, body: str, 
                   is_html: bool = False, cc_email: Optional[List[str]] = None,
                   bcc_email: Optional[List[str]] = None,
                   attachments: Optional[List[Dict[str, Any]]] = None) -> str:
        """
        Send an email with attachments - FIXED VERSION
        Returns: Message ID
        """
        print(f"\n📤 ===== SMTP CLIENT: SEND EMAIL START =====")
        print(f"   From: {self.username}")
        print(f"   To: {to_email}")
        print(f"   Subject: {subject}")
        print(f"   Body length: {len(body)}")
        print(f"   Attachments: {len(attachments) if attachments else 0}")
        
        # Create message
        msg = MIMEMultipart()
        msg['From'] = self.username
        msg['To'] = ', '.join(to_email)
        
        if cc_email:
            msg['Cc'] = ', '.join(cc_email)
        
        msg['Subject'] = subject
        msg['Message-ID'] = make_msgid()
        
        # All recipients
        all_recipients = to_email.copy()
        if cc_email:
            all_recipients.extend(cc_email)
        if bcc_email:
            all_recipients.extend(bcc_email)
        
        # Add email body
        print(f"   📝 Adding body...")
        if is_html:
            msg.attach(MIMEText(body, 'html'))
        else:
            msg.attach(MIMEText(body, 'plain'))
        
        # ✅ FIXED: Add attachments with proper error handling
        if attachments and len(attachments) > 0:
            print(f"   📎 Processing {len(attachments)} attachments...")
            
            for idx, attachment in enumerate(attachments):
                filename = "unknown_file"
                try:
                    filename = attachment.get('filename', f'attachment_{idx}')
                    content_type = attachment.get('content_type', 'application/octet-stream')
                    base64_content = attachment.get('base64_content', '')
                    
                    print(f"   📄 Attachment {idx+1}: {filename}")
                    
                    if not base64_content:
                        print(f"   ⚠️ Skipping: No base64 content")
                        continue
                    
                    # Clean filename
                    filename = filename.replace('\n', '').replace('\r', '')
                    
                    # Decode base64
                    print(f"   🔍 Decoding base64 ({len(base64_content)} chars)...")
                    try:
                        file_data = base64.b64decode(base64_content)
                        print(f"   ✅ Decoded: {len(file_data)} bytes")
                    except Exception as e:
                        print(f"   ❌ Base64 decode failed: {e}")
                        continue
                    
                    # Create MIME part
                    maintype, subtype = content_type.split('/', 1) if '/' in content_type else ('application', 'octet-stream')
                    
                    print(f"   🛠️ Creating MIME part: {maintype}/{subtype}")
                    mime_part = MIMEBase(maintype, subtype)
                    mime_part.set_payload(file_data)
                    
                    # Encode and set headers
                    encoders.encode_base64(mime_part)
                    mime_part.add_header(
                        'Content-Disposition',
                        'attachment',
                        filename=filename
                    )
                    
                    # Add to message
                    msg.attach(mime_part)
                    print(f"   ✅ Added: {filename}")
                    
                except Exception as e:
                    print(f"   ❌ Error adding attachment {filename}: {str(e)}")
                    import traceback
                    traceback.print_exc()
        else:
            print(f"   ℹ️ No attachments to add")
        
        # Connect to SMTP server and send
        print(f"   🔗 Connecting to SMTP: {self.smtp_host}:{self.smtp_port}")
        
        try:
            server = smtplib.SMTP(self.smtp_host, self.smtp_port, timeout=30)
            print(f"   ⚡ Connection established")
            
            if self.use_tls:
                print(f"   🔒 Starting TLS...")
                server.starttls()
                print(f"   ✅ TLS enabled")
            
            print(f"   🔑 Logging in as: {self.username}")
            server.login(self.username, self.password)
            print(f"   ✅ Login successful")
            
            print(f"   📤 Sending email to {len(all_recipients)} recipients...")
            server.send_message(msg)
            print(f"   ✅ Email sent successfully!")
            
            # Close connection
            server.quit()
            print(f"   🔌 Connection closed")
            
            # Extract message ID
            message_id = msg.get('Message-ID', '')
            return message_id
            
        except Exception as e:
            print(f"   ❌ SMTP Error: {str(e)}")
            import traceback
            traceback.print_exc()
            raise