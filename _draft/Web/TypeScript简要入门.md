# TypeScript简要入门

鸿蒙eTS框架使用扩展的TypeScript语言，所以先了解下TS。

* 内容来源于： [文档简介 · TypeScript中文网 · TypeScript——JavaScript的超集 (tslang.cn)](https://www.tslang.cn/docs/home.html)

* 所有练习直接在网页上进行： [学习乐园 · TypeScript——JavaScript的超集 (tslang.cn)](https://www.tslang.cn/play/index.html)



不知道华为的eTS 基于哪个版本的TS，也尚不清楚华为对eTS扩展部分的内容。所以暂时只学习标准的TS。



## 类型注解

* **number**
* **string**
* **[] / Array**
* **Tuple `[string,number]`**
* **enum**
* **any**
* **void**
* **Null/undefined**
* **Object**

### 类型注解

TS 最为显著的就是为JS添加了类型注解。如下：

```tsx
let isDone: boolean = false;
```

其中`: boolean` 就是类型注解。

因此我们需要知道对应类型的类型注解怎么写：

| 类型   | 写法                        | 示例及说明                                                   |
| ------ | --------------------------- | ------------------------------------------------------------ |
| 数字   | `number`                    |                                                              |
| 字符串 | `string`                    |                                                              |
| 数组   | `[]`<br />`Array<元素类型>` | 如： `let list: number[] = [1, 2, 3];`<br />`let list: Array<number> = [1, 2, 3];` |
|        |                             |                                                              |

### 扩展

上述是对JS的基本类型的注解写法，另外TS有对JS类型的一些扩展。

#### 元组 Tuple

```typescript
let x: [string, number];
```

#### 枚举

```typescript
enum Color {Red, Green, Blue}
let c: Color = Color.Green;
```

#### Any

对不确定的类型跳过编译检查（在编译时可选择地包含或移除类型检查）

```typescript
let notSure: any = 4;
notSure = "maybe a string instead";
notSure = false; // okay, definitely a boolean
```

#### Void

`void`类型像是与`any`类型相反，它表示没有任何类型。 当一个函数没有返回值时，其返回值类型是 `void`：

```typescript
function warnUser(): void {
    console.log("This is my warning message");
}
```

#### Null 和 Undefined

* 默认情况下`null`和`undefined`是所有类型的子类型。 就是说你可以把 `null`和`undefined`赋值给`number`类型的变量。
* 然而，当你指定了`--strictNullChecks`标记，`null`和`undefined`只能赋值给`void`和它们各自。
* 鼓励尽可能地使用`--strictNullChecks`

#### Never

永不存在的值的类型

* `never`类型是任何类型的子类型，也可以赋值给任何类型；然而，*没有*类型是`never`的子类型或可以赋值给`never`类型（除了`never`本身之外）。 即使 `any`也不可以赋值给`never`。
* `never`类型是那些总是会抛出异常或根本就不会有返回值的函数表达式或箭头函数表达式的返回值类型
*  即使 `any`也不可以赋值给`never`。

```typescript
// 返回never的函数必须存在无法达到的终点
function error(message: string): never {
    throw new Error(message);
}

// 推断的返回值类型为never
function fail() {
    return error("Something failed");
}

// 返回never的函数必须存在无法达到的终点
function infiniteLoop(): never {
    while (true) {
    }
}
```

#### Object

`object`表示非原始类型，也就是除`number`，`string`，`boolean`，`symbol`，`null`或`undefined`之外的类型。(==symbol是什么类型？⁉️==)

```typescript
declare function create(o: object | null): void;

create({ prop: 0 }); // OK
create(null); // OK

create(42); // Error
create("string"); // Error
create(false); // Error
create(undefined); // Error
```

### 类型断言

类似其他语言的类型转换，告诉TypeScript的编译器，这个类型具体是什么

* 写法：

  1. 尖括号

     ```typescript
     let someValue: any = "this is a string";
     
     let strLength: number = (<string>someValue).length;
     ```

  2. as 语法

     ```typescript
     let someValue: any = "this is a string";
     
     let strLength: number = (someValue as string).length;
     ```

## 变量声明

### 变量声明的三种方式

1. `let`：块作用域，

   * 不能在被声明之前读或写（暂时性死区）

   * 嵌套作用域中内层可以屏蔽外层同名变量(内层i可以屏蔽外层i 得到正确的结果)

     ```typescript
     for (let i = 0; i < matrix.length; i++) {
             var currentRow = matrix[i];
             for (let i = 0; i < currentRow.length; i++) {
                 sum += currentRow[i];
             }
         }
     ```

     

2. `const` ： 阻止再次赋值

3. `var`： 函数作用域，函数中段声明，函数头部也可以使用的哦。

   * 声明多次只创建一个变量



### 解构

* 数组解构

```typescript
let input = [1, 2];
let [first, second] = input;
console.log(first); // outputs 1
console.log(second); // outputs 2
```

* 对象解构

  ```typescript
  let o = {
      a: "foo",
      b: 12,
      c: "bar"
  };
  let { a, b } = o;
  ({ a, b } = { a: "baz", b: 101 });
  ```

* 属性重命名

  ```typescript
  let { a: newName1, b: newName2 } = o;
  // 带类型的完整写法
  let {a, b}: {a: string, b: number} = o;
  ```

* ​	默认值（在属性为 undefined 时使用缺省值）

  ```typescript
  function keepWholeObject(wholeObject: { a: string, b?: number }) {
      let { a, b = 1001 } = wholeObject;
  }
  ```

### 展开

与解构相反，可将

* 一个数组展开为另一个数组，或者
* 将一个对象展开为另外一个对象

```typescript
let first = [1, 2];
let second = [3, 4];
let bothPlus = [0, ...first, ...second, 5];
```



## 接口

```typescript
interface LabelledValue {
  label: string;
}

function printLabel(labelledObj: LabelledValue) {
  console.log(labelledObj.label);
}

let myObj = {size: 10, label: "Size 10 Object"};
printLabel(myObj);
```

### 可选属性

* 接口属性不是必须的（只在某些条件下存在，或者根本不存在）

```typescript
interface SquareConfig {
  color?: string;
  width?: number;
}

function createSquare(config: SquareConfig): {color: string; area: number} {
  let newSquare = {color: "white", area: 100};
  if (config.color) {
    newSquare.color = config.color;
  }
  if (config.width) {
    newSquare.area = config.width * config.width;
  }
  return newSquare;
}
// 给函数传入的参数对象中只有部分属性赋值了
let mySquare = createSquare({color: "black"});
```



### 只读属性

只能在对象刚刚创建的时候修改其值。 

```typescript
interface Point {
    readonly x: number;
    readonly y: number;
}
```



### 函数类型

* 一个只有参数列表和返回值类型的函数定义
* 参数列表里的每个参数都需要名字和类型

```typescript
interface SearchFunc {
  (source: string, subString: string): boolean;
}
```

### 可索引类型

与使用接口描述函数类型差不多，我们也可以描述那些能够“通过索引得到”的类型，比如`a[10]`或`ageMap["daniel"]`。 可索引类型具有一个 *索引签名*，它描述了对象索引的类型，还有相应的索引返回值类型。 让我们看一个例子：

```ts
interface StringArray {
  [index: number]: string;
}

let myArray: StringArray;
myArray = ["Bob", "Fred"];

let myStr: string = myArray[0];
```



### 类类型

#### 实现接口 - implements

与C#或Java里接口的基本作用一样，TypeScript也能够用它来明确的强制一个类去符合某种契约。

```ts
interface ClockInterface {
    currentTime: Date;
    setTime(d: Date);
}

class Clock implements ClockInterface {
    currentTime: Date;
    setTime(d: Date) {
        this.currentTime = d;
    }
    constructor(h: number, m: number) { }
}
```



### 接口继承  - extends

```ts
interface Shape {
    color: string;
}

interface PenStroke {
    penWidth: number;
}

interface Square extends Shape, PenStroke {
    sideLength: number;
}

let square = <Square>{};
square.color = "blue";
square.sideLength = 10;
square.penWidth = 5.0;
```



### 混合类型

一个例子就是，一个对象可以同时做为函数和对象使用，并带有额外的属性。

```ts
interface Counter {
    (start: number): string;
    interval: number;
    reset(): void;
}

function getCounter(): Counter {
    let counter = <Counter>function (start: number) { };
    counter.interval = 123;
    counter.reset = function () { };
    return counter;
}

let c = getCounter();
c(10);
c.reset();
c.interval = 5.0;
```



### 接口继承类

当接口继承了一个类类型时，它会**继承类的成员但不包括其实现**。 

就好像接口声明了所有类中存在的成员，但并没有提供具体实现一样。 接口同样会继承到类的private和protected成员。 这意味着当你创建了一个接口继承了一个拥有私有或受保护的成员的类时，这个接口类型只能被这个类或其子类所实现（implement）。



## 类

### 简单示例

```typescript
class Greeter {
    greeting: string;
    constructor(message: string) {
        this.greeting = message;
    }
    greet() {
        return "Hello, " + this.greeting;
    }
}

let greeter = new Greeter("world");
```

* 编译后的JavaScript可以在所有主流浏览器和平台上运行

### 继承 - extends

类从基类中继承了属性和方法

```ts
class Animal {
    move(distanceInMeters: number = 0) {
        console.log(`Animal moved ${distanceInMeters}m.`);
    }
}

class Dog extends Animal {
    bark() {
        console.log('Woof! Woof!');
    }
}

const dog = new Dog();
dog.bark();
dog.move(10);
dog.bark();
```

* 构造函数必须使用super调用父类的构造



### 访问修饰符

* 默认都是 `public`
* `private` 不能在类的外部访问
* `protected`成员在派生类中仍然可以访问
* TypeScript使用的是结构性类型系统。 当我们比较两种不同的类型时，并不在乎它们从何处而来，如果所有成员的类型都是兼容的，我们就认为它们的类型是兼容的。然而，当我们比较带有 `private`或 `protected`成员的类型的时候，情况就不同了。 如果其中一个类型里包含一个 `private`成员，那么只有当另外一个类型中也存在这样一个 `private`成员， 并且它们都是来自同一处声明时，我们才认为这两个类型是兼容的。 对于 `protected`成员也使用这个规则。

### readonly

* 使用 `readonly`关键字将属性设置为只读的。 只读属性必须在声明时或构造函数里被初始化。

* 参数属性: 把声明和赋值合并至一处

  ```ts
  class Octopus {
      readonly numberOfLegs: number = 8;
      constructor(readonly name: string) {
      }
  }
  ```

  

### getter/setter

* 成员私有
* 存取器要求你将编译器设置为输出ECMAScript 5或更高。
* 只带有 `get`不带有 `set`的存取器自动被推断为 `readonly`

```ts
let passcode = "secret passcode";

class Employee {
    private _fullName: string;

    get fullName(): string {
        return this._fullName;
    }

    set fullName(newName: string) {
        if (passcode && passcode == "secret passcode") {
            this._fullName = newName;
        }
        else {
            console.log("Error: Unauthorized update of employee!");
        }
    }
}

let employee = new Employee();
employee.fullName = "Bob Smith";
if (employee.fullName) {
    alert(employee.fullName);
}
```



### 静态属性 - static

* 使用 static 声明

* 访问时加上类名

  ```ts
  class Grid {
      static origin = {x: 0, y: 0};
      calculateDistanceFromOrigin(point: {x: number; y: number;}) {
          let xDist = (point.x - Grid.origin.x);
          let yDist = (point.y - Grid.origin.y);
          return Math.sqrt(xDist * xDist + yDist * yDist) / this.scale;
      }
      constructor (public scale: number) { }
  }
  
  let grid1 = new Grid(1.0);  // 1x scale
  let grid2 = new Grid(5.0);  // 5x scale
  
  console.log(grid1.calculateDistanceFromOrigin({x: 10, y: 10}));
  console.log(grid2.calculateDistanceFromOrigin({x: 10, y: 10}));
  ```

  

### 抽象类

不同于接口，抽象类可以包含成员的实现细节。 `abstract`关键字是用于定义抽象类和在抽象类内部定义抽象方法。

```ts
abstract class Department {

    constructor(public name: string) {
    }

    printName(): void {
        console.log('Department name: ' + this.name);
    }

    abstract printMeeting(): void; // 必须在派生类中实现
}
```

### 接口继承与类继承

* 继承都使用extends
* 接口继承接口可继承多个 
* 接口也可以继承类，只保留接口，不保留实现





## 函数

### 函数类型

函数类型由参数类型和返回类型组成。

* 定义时的类型书写

  ```ts
  function add(x: number, y: number): number {
      return x + y;
  }
  
  let myAdd = function(x: number, y: number): number { return x + y; };
  ```

* 变量赋值完整类型书写 （函数和返回值类型之前使用( `=>`)符号）

  ```ts
  let myAdd: (x: number, y: number) => number =
      function(x: number, y: number): number { return x + y; };
  ```

  * 函数如果没有返回，则返回类型需要写为 void 

* 推断类型： 在赋值语句的一边指定了类型但是另一边没有类型的话，TypeScript编译器会自动识别出类型：

### 可选参数&默认参数

*  在TypeScript里我们可以在参数名旁使用 `?`实现可选参数的功能。 

  ```ts
  function buildName(firstName: string, lastName?: string) {
      if (lastName)
          return firstName + " " + lastName;
      else
          return firstName;
  }
  ```

* 在TypeScript里，我们也可以为参数提供一个默认值当用户没有传递这个参数或传递的值是`undefined`时。 

  ```ts
  function buildName(firstName: string, lastName = "Smith") {
      return firstName + " " + lastName;
  }
  ```

### 剩余参数

必要参数，默认参数和可选参数有个共同点：它们表示某一个参数。 有时，你想同时操作多个参数，或者你并不知道会有多少参数传递进来。 在JavaScript里，你可以使用 `arguments`来访问所有传入的参数。

在TypeScript里，你可以把所有参数收集到一个变量里：

```ts
function buildName(firstName: string, ...restOfName: string[]) {
  return firstName + " " + restOfName.join(" ");
}

let buildNameFun: (fname: string, ...rest: string[]) => string = buildName;
```



### this (待测试)

[函数 · TypeScript中文网 · TypeScript——JavaScript的超集 (tslang.cn)](https://www.tslang.cn/docs/handbook/functions.html)

如果你想了解JavaScript里的 `this`是如何工作的，那么首先阅读Yehuda Katz写的[Understanding JavaScript Function Invocation and "this"](http://yehudakatz.com/2011/08/11/understanding-javascript-function-invocation-and-this/)。 Yehuda的文章详细的阐述了 `this`的内部工作原理，因此我们这里只做简单介绍。

我们可以在函数被返回时就绑好正确的`this`。 这样的话，无论之后怎么使用它，都会引用绑定的‘deck’对象。 我们需要改变函数表达式来使用ECMAScript 6箭头语法。 箭头函数能保存函数创建时的 `this`值，而不是调用时的值：

```ts
let deck = {
    suits: ["hearts", "spades", "clubs", "diamonds"],
    cards: Array(52),
    createCardPicker: function() {
        // NOTE: the line below is now an arrow function, allowing us to capture 'this' right here
        return () => {
            let pickedCard = Math.floor(Math.random() * 52);
            let pickedSuit = Math.floor(pickedCard / 13);

            return {suit: this.suits[pickedSuit], card: pickedCard % 13};
        }
    }
}

let cardPicker = deck.createCardPicker();
let pickedCard = cardPicker();

alert("card: " + pickedCard.card + " of " + pickedCard.suit);
```



### 重载

根据参数和返回类型



## 泛型

```ts
interface Lengthwise {
    length: number;
}

function loggingIdentity<T extends Lengthwise>(arg: T): T {
    console.log(arg.length);  // Now we know it has a .length property, so no more error
    return arg;
}
```

