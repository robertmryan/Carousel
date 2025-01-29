//
//  CarouselViewController.swift
//  Carousel
//
//  Created by Robert Ryan on 1/29/25.
//

import UIKit

extension Bundle {
    func decode<T: Decodable>(_ type: T.Type = T.self, from file: String) throws -> T {
        guard let url = url(forResource: file, withExtension: nil) else {
            throw URLError(.badURL)
        }
        let data = try Data(contentsOf: url)
        let decoder = JSONDecoder()
        return try decoder.decode(T.self, from: data)
    }
}

class CarouselViewController: UIViewController {
    var collectionView: UICollectionView!
    var dataSource: UICollectionViewDiffableDataSource<Section, Download>?
    var carouselData: [CarouselData] = []    // the original JSON
    var downloads: [Item.ID: Download] = [:] // the downloads state

    override func viewDidLoad() {
        super.viewDidLoad()

        setupCollectionView()
//        setupScrollView()
        setupDownloadItems()
    }

//    func setupScrollView() {
//        collectionView.scrollToItem(at: IndexPath(item: 0, section: 0), at: .centeredHorizontally, animated: false)
//    }

    func setupDownloadItems() {
        carouselData = try! Bundle.main.decode([CarouselData].self, from: "carouselData.json")

        for carousel in carouselData {
            for item in carousel.items {
                downloads[item.id] = Download(item: item)
            }
        }

        reloadData()
    }

    func createDataSource() {
        dataSource = UICollectionViewDiffableDataSource<Section, Download>(collectionView: collectionView) { [weak self] collectionView, indexPath, item in
            self?.configure(CarouselCell.self, with: item, for: indexPath)
        }
    }

    func configure<T: SelfConfiguringCell>(_ cellType: T.Type, with item: Download, for indexPath: IndexPath) -> T {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: cellType.reuseIdentifier, for: indexPath) as? T else { fatalError("\(cellType)") }
        cell.configure(with: item)
        return cell
    }

    func reloadData() {
        var snapshot = NSDiffableDataSourceSnapshot<Section, Download>()

        for carousel in carouselData {
            snapshot.appendSections([carousel.section])
            let downloads: [Download] = carousel.items.compactMap { item in
                self.downloads[item.id]
            }
            snapshot.appendItems(downloads)
        }
        dataSource?.apply(snapshot)
    }

    func setupCollectionView() {
        collectionView = UICollectionView(frame: view.bounds, collectionViewLayout: createCompositionalLayout())
        collectionView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        collectionView.isScrollEnabled = false
        collectionView.delegate = self
        collectionView.contentInsetAdjustmentBehavior = .never
        view.addSubview(collectionView)
        collectionView.register(CarouselCell.self, forCellWithReuseIdentifier: CarouselCell.reuseIdentifier)
        createDataSource()
    }

    func createCompositionalLayout() -> UICollectionViewLayout {
        UICollectionViewCompositionalLayout { (sectionIndex: Int, layoutEnvironment: NSCollectionLayoutEnvironment) -> NSCollectionLayoutSection? in

            let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1),
                                                  heightDimension: .fractionalHeight(1))
            let item = NSCollectionLayoutItem(layoutSize: itemSize)

            let groupWidth = (layoutEnvironment.container.contentSize.width * 1.05)/3
            let groupSize = NSCollectionLayoutSize(widthDimension: .absolute(groupWidth),
                                                   heightDimension: .absolute(groupWidth))
            let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitems: [item])

            let section = NSCollectionLayoutSection(group: group)
            section.contentInsets = NSDirectionalEdgeInsets(
                top: (layoutEnvironment.container.contentSize.height/2) - (groupWidth/2),
                leading: 0,
                bottom: 0,
                trailing: 0)
            section.interGroupSpacing = 64
            section.orthogonalScrollingBehavior = .groupPagingCentered
            section.contentInsetsReference = .none
            section.visibleItemsInvalidationHandler = { (items, offset, environment) in

                items.forEach { item in
                    let distanceFromCenter = abs((item.frame.midX - offset.x) - environment.container.contentSize.width / 2.0)
                    let minScale: CGFloat = 0.7
                    let maxScale: CGFloat = 1.1
                    let scale = max(maxScale - (distanceFromCenter / environment.container.contentSize.width), minScale)
                    item.transform = CGAffineTransform(scaleX: scale, y: scale)
                }
            }

            return section
        }
    }
}

extension CarouselViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        print(#function)

        let item = carouselData[indexPath.section].items[indexPath.item]
        downloads[item.id]?.start()
    }
}

// MARK: - JSON data

extension CarouselViewController {
    struct CarouselData: Decodable, Hashable {
        let section: Section
        let items: [Item]
    }

    struct Section: Decodable, Hashable, Identifiable {
        let id: Int
        let title: String
    }

    struct Item: Decodable, Hashable, Identifiable {
        let id: Int
        let title: String
    }
}
