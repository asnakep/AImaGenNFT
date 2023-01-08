#!/bin/env python3

import requests
import replicate
import subprocess as sp
from   essential_generators import DocumentGenerator

### Generate Random Sentence
gen = DocumentGenerator()
generated = gen.sentence()

### Generate AI Image based on Random Sentence
model = replicate.models.get("stability-ai/stable-diffusion")
output_url = model.predict(prompt=generated)[0]
response = requests.get(output_url)
open("out-0.png", "wb").write(response.content)
