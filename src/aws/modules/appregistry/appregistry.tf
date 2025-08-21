# 1. Define the Application
resource "aws_servicecatalogappregistry_application" "main" { # Corrected name
  name        = var.application_name
  description = "Application for ${var.application_name} resources."
}

# 2. Define an Attribute Group for resources
resource "aws_servicecatalogappregistry_attribute_group" "application_attributes" { # Corrected name
  name        = "${var.application_name}-ApplicationAttributes"
  description = "Overall attributes for the ${var.application_name} 3-tier application."
  attributes = jsonencode({
    "managedBy"   = "terraform",
    "application" = var.application_name
  })
}

# 3. Associate the Attribute Group with the Application
resource "aws_servicecatalogappregistry_attribute_group_association" "app_application_association" {
  application_id     = aws_servicecatalogappregistry_application.main.id
  attribute_group_id = aws_servicecatalogappregistry_attribute_group.application_attributes.id
}
