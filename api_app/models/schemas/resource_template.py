from typing import Dict, List

from pydantic import BaseModel, Field

from models.domain.resource_template import ResourceTemplate, Property


class ResourceTemplateInCreate(BaseModel):
    name: str = Field(title="Template name")
    version: str = Field(title="Template version")
    current: bool = Field(title="Mark this version as current")
    json_schema: Dict = Field(title="JSON Schema compliant template")


class ResourceTemplateInResponse(ResourceTemplate):
    system_properties: Dict[str, Property] = Field(title="System properties")


class ResourceTemplateInformation(BaseModel):
    name: str = Field(title="Template name")
    title: str = Field(title="Template title", default="")
    description: str = Field(title="Template description", default="")


class ResourceTemplateInformationInList(BaseModel):
    templates: List[ResourceTemplateInformation]

    class Config:
        schema_extra = {
            "example": {
                "templates": [
                    {
                        "name": "tre-workspace-base",
                        "title": "Base Workspace",
                        "description": "base description"
                    },
                    {
                        "name": "tre-workspace-base",
                        "title": "Base Workspace",
                        "description": "base description"
                    }
                ]
            }
        }
