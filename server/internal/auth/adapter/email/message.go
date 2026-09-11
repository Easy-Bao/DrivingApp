package email

func verificationBody(code string) string {
	return "Your DriveApp verification code is " + code + ". It expires in 10 minutes.\n"
}
