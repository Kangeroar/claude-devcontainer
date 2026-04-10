---
name: likec4-diagramming
description: LikeC4 diagramming library syntax and patterns
---
# LikeC4 Syntax Guide

This skill provides a concise reference for generating LikeC4 diagrams from code, focusing on basic shapes (squares/rectangles, circles, diamonds etc.), connections, and nested graphs.

## Basic Structure
A LikeC4 `.c4` file consists of three main blocks: `specification`, `model`, and `views`.

```likec4
specification {
  element system
  element component
  
  // Define custom elements and their shapes
  element CustomSquare {
    style { shape rectangle }
  }
  element CustomCircle {
    style { shape cylinder } // LikeC4 supports storage, cylinder, queue, browser, mobile, person
  }
}

model {
  // Define structural elements and relationships
  system systemA {
    component comp1
    component comp2
  }
  
  // Connectors
  systemA.comp1 -> systemA.comp2 'sends data to'
}

views {
  // Define what to render
  view index {
    include *
  }
}
```

## Nested Graphs
To allow for nested graphs (subgraphs where clicking an element opens up its internals), you define elements within other elements in the `model` block, and then use view navigation in the `views` block.

```likec4
specification {
  element system
  element component
}

model {
  // Outer element
  system MySystem {
    // Nested elements
    component Frontend
    component Backend {
      component Database
      component API
      API -> Database 'queries'
    }
    
    Frontend -> Backend.API 'calls'
  }
}

views {
  // The high-level view
  view root {
    include MySystem
  }
  
  // The nested view that shows internals of MySystem
  view nestedSystemView of MySystem {
    include *
  }
  
  // The nested view of the Backend
  view nestedBackendView of MySystem.Backend {
    include *
  }
}
```
In LikeC4 tooling, relationships and nesting inherently provide interactive click-through from the high-level `root` view down directly into the configured `of` sub-views.

## Basic Shapes Reference

Within the `specification` block, define styling for elements. LikeC4 provides specific keywords for shapes:

* **Square / Rectangle**: `shape rectangle` (default)
* **Circle / Cylinder**: `shape cylinder` or `shape person` (for actors)
* **Storage / Database**: `shape storage`
* **Additional Shapes**: `component`, `browser`, `mobile`, `queue`, `bucket`, `document`

*Note: While there's no native "diamond" shape primitive built-in to the base C4 model shapes, standard boxes, rounded rectangles, and cylinders are mostly used to portray components and boundaries.*

## Connectors

Connect elements in the `model` block using `->`:
* Source -> Target: `sourceId -> targetId 'description'` 

## Common Pitfalls & Best Practices

### 1. ElementKind Resolution
Every element kind used in the `model` block (e.g., `system`, `component`, `user`) **MUST** be defined in the `specification` block. If you use a keyword like `system` in your model without `element system` in your specification, LikeC4 will fail to resolve the reference.

### 2. Invalid Parent-Child Relationships
You **cannot** create an explicit relationship arrow (`->`) between a parent element and its direct child.
* **Bad**: `MySystem -> MySystem.Frontend`
* **Good**: Simply nest `Frontend` inside `MySystem`. The relationship is implied by containment.

### 3. View Resolution
When defining a view `of SomeElement`, ensure `SomeElement` exists in the model. If you rename an element in the model, you must update all corresponding views.

### 4. Validation
Always run `npx likec4 check .` or `npx likec4 build .` to validate your syntax. Errors often point to specific line numbers where resolution or relationship rules are violated.
