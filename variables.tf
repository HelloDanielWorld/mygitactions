 variable "REPO" {
   type = string
   description = "URL of your Github repository"
 }

 variable "TOKEN" {
   type = string
   sensitive = true
   description = "Personal Access token for your Github"
}