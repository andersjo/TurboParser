// Copyright (c) 2012-2015 Andre Martins
// All Rights Reserved.
//
// This file is part of TurboParser 2.3.
//
// TurboParser 2.3 is free software: you can redistribute it and/or modify
// it under the terms of the GNU Lesser General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// TurboParser 2.3 is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU Lesser General Public License for more details.
//
// You should have received a copy of the GNU Lesser General Public License
// along with TurboParser 2.3.  If not, see <http://www.gnu.org/licenses/>.

#include "DependencyWriter.h"
#include "DependencyInstance.h"
#include "DependencyPipe.h"
#include <iostream>
#include <sstream>

void DependencyWriter::Write(Instance *instance) {
  DependencyInstance *dependency_instance = 
    static_cast<DependencyInstance*>(instance);

  for (int i = 1; i < dependency_instance->size(); ++i) {
    os_ << i << "\t";
    os_ << dependency_instance->GetForm(i) << "\t";
    os_ << dependency_instance->GetLemma(i) << "\t";
    os_ << dependency_instance->GetCoarsePosTag(i) << "\t";
    os_ << dependency_instance->GetPosTag(i) << "\t";
    os_ << "_" << "\t"; // Change this later
    os_ << dependency_instance->GetHead(i) << "\t";
    os_ << dependency_instance->GetDependencyRelation(i) << endl;
  }
  os_ << endl;
}


void DependencyWriter::WriteFull(Pipe *pipe, Instance *instance, Parts *parts, vector<double> &scores, vector<double> &predicted_outputs) {
  DependencyPipe *dependency_pipe = static_cast<DependencyPipe*>(pipe);
  DependencyParts *dependency_parts = static_cast<DependencyParts*>(parts);
  DependencyInstance *dependency_instance = 
    static_cast<DependencyInstance*>(instance);

  int offset, num_arcs;
  if (dependency_pipe->GetDependencyOptions()->labeled()) {
  	dependency_parts->GetOffsetLabeledArc(&offset, &num_arcs);
  } else {
  	dependency_parts->GetOffsetArc(&offset, &num_arcs);
  }




  for (int i = 1; i < dependency_instance->size(); ++i) {
    os_ << i << "\t";
    os_ << dependency_instance->GetForm(i) << "\t";
    os_ << dependency_instance->GetLemma(i) << "\t";
    os_ << dependency_instance->GetCoarsePosTag(i) << "\t";
    os_ << dependency_instance->GetPosTag(i) << "\t";
    os_ << "_" << "\t"; // Change this later
    os_ << dependency_instance->GetHead(i) << "\t";
    os_ << dependency_instance->GetDependencyRelation(i) << "\t";

    // Output possible edge scores 
    if (dependency_pipe->GetDependencyOptions()->labeled()) {
      for (int r = 0; r < num_arcs; ++r) {
        DependencyPartLabeledArc *arc = 
          static_cast<DependencyPartLabeledArc*>((*dependency_parts)[offset + r]);
        if (arc->modifier() == i) {
          string label_name = dependency_pipe->GetDependencyDictionary()->GetLabelName(arc->label());
          os_ << arc->head() << "-" << label_name << ":" << scores[offset + r] << " ";
        }
      }
      os_ << "\n";
    } else {
      for (int r = 0; r < num_arcs; ++r) {
        DependencyPartArc *arc = 
          static_cast<DependencyPartArc*>((*dependency_parts)[offset + r]);
        if (arc->modifier() == i) {
          os_ << arc->head() << ":" << scores[offset + r] << " ";
        }
      }
      os_ << "\n";
    }

  }
  os_ << endl;
}