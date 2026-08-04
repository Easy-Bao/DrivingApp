package email

import "fmt"

func verificationBody(code string) string {
	return fmt.Sprintf("Your DriveApp verification code is %s. It expires in 10 minutes.\n", code)
}
