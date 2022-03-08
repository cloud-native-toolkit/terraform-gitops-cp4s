
 resource null_resource write_outputs {
   provisioner "local-exec" {
     command = "echo \"$${OUTPUT}\" > gitops-output.json"

     environment = {
       OUTPUT = jsonencode({
         name        = module.cp4s.name
         branch      = module.cp4s.branch
         layer       = module.cp4s.layer
         layer_dir   = module.cp4s.layer == "infrastructure" ? "1-infrastructure" : (module.cp4s.layer == "services" ? "2-services" : "3-applications")
         type        = module.cp4s.type
       })
     }
   }
}
