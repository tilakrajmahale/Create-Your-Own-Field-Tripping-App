// Use .apex files to store anonymous Apex.
// You can execute anonymous Apex in VS Code by selecting the
//     apex text and running the command:
//     SFDX: Execute Anonymous Apex with Currently Selected Text
// You can also execute the entire file by running the command:
//     SFDX: Execute Anonymous Apex with Editor Contents


BinaryTree bt = new BinaryTree();
bt.addNode(8);
bt.addNode(4);
bt.addNode(10);
bt.addNode(2);
bt.addNode(6);
bt.addNode(20);
bt.addNode(9);
bt.addNode(5);

/*System.debug(bt.root.data);
System.debug(bt.root.left.data);
System.debug(bt.root.left.left.data);
System.debug(bt.root.left.right.data);
System.debug(bt.root.right.data);
System.debug(bt.root.right.right?.data);
System.debug(bt.root.right.left?.data);

System.debug('InOrderTraversal -->>');
bt.inOrderTraversal(bt.root);
System.debug('PreOrderTraversal -->>');
bt.preOrderTraversal(bt.root);
System.debug('PostOrderTraversal -->>');
bt.postOrderTraversal(bt.root);
*/

Node n = bt.root.left.left;
n.data = 6;

//bt.preOrderTraversal(bt.root);

System.debug(bt.isBinarySearchTree(bt));